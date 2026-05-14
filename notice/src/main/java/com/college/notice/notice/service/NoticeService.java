package com.college.notice.notice.service;

import com.college.notice.auth.entity.User;
import com.college.notice.auth.repository.UserRepository;
import com.college.notice.analytics.entity.NoticeStatus;
import com.college.notice.analytics.repository.NoticeStatusRepository;
import com.college.notice.notice.dto.ActivityItemResponse;
import com.college.notice.notice.dto.NoticeRequest;
import com.college.notice.notice.dto.NoticeReplyRequest;
import com.college.notice.notice.dto.NoticeReplyResponse;
import com.college.notice.notice.dto.NoticeResponse;
import com.college.notice.notice.dto.NoticeTargetResponse;
import com.college.notice.notice.entity.Notice;
import com.college.notice.notice.entity.NoticeReply;
import com.college.notice.notice.entity.NoticeTarget;
import com.college.notice.notice.event.NoticeCreatedEvent;
import com.college.notice.notice.config.NoticeExpiryPolicy;
import com.college.notice.notice.repository.NoticeReplyRepository;
import com.college.notice.notice.repository.NoticeRepository;
import com.college.notice.notification.entity.Notification;
import com.college.notice.notification.repository.NotificationRepository;
import com.college.notice.shared.constants.Role;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NoticeService {

    private final NoticeRepository noticeRepository;
    private final UserRepository userRepository;
    private final NotificationRepository notificationRepository;
    private final ApplicationEventPublisher eventPublisher;
    private final NoticeExpiryPolicy noticeExpiryPolicy;
    private final NoticeStatusRepository noticeStatusRepository;
    private final NoticeReplyRepository noticeReplyRepository;

    @Transactional
    public NoticeResponse createNotice(NoticeRequest request) {
        User currentUser = getCurrentUser();

        Notice notice = Notice.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .category(normalizeCategory(request.getCategory()))
                .priority(request.getPriority())
                .pinned(request.isPinned())
                .viewCount(0L)
                .expiryDate(request.getExpiryDate())
                .createdBy(currentUser)
                .targets(new ArrayList<>())
                .build();

        applyTargets(notice, request);
        Notice savedNotice = noticeRepository.save(notice);

        eventPublisher.publishEvent(new NoticeCreatedEvent(savedNotice.getId()));
        return toResponse(savedNotice, Optional.empty());
    }

    @Transactional(readOnly = true)
    public List<NoticeResponse> getNoticesForUser() {
        User currentUser = getCurrentUser();
        List<Notice> notices;
        if (currentUser.getRole() == Role.ADMIN) {
            notices = noticeRepository.findAllWithTargetsForAdmin();
        } else {
            notices = noticeRepository.findActiveNoticesVisibleForUser(
                    currentUser.getDepartment(),
                    currentUser.getYear(),
                    noticeExpiryPolicy.visibilityCutoff()
            );
        }

        return notices.stream()
                .map(notice -> {
                    Optional<Notification> notification = notificationRepository
                            .findFirstByNoticeIdAndUserIdOrderByIdAsc(
                            notice.getId(),
                            currentUser.getId()
                    );
                    return toResponse(notice, notification);
                })
                .toList();
    }

    @Transactional
    public NoticeResponse updateNotice(Long noticeId, NoticeRequest request) {
        Notice notice = noticeRepository.findByIdWithTargets(noticeId)
                .orElseThrow(() -> new RuntimeException("Notice not found"));

        notice.setTitle(request.getTitle());
        notice.setDescription(request.getDescription());
        notice.setCategory(normalizeCategory(request.getCategory()));
        notice.setPriority(request.getPriority());
        notice.setPinned(request.isPinned());
        notice.setExpiryDate(request.getExpiryDate());
        applyTargets(notice, request);

        Notice updatedNotice = noticeRepository.save(notice);
        return toResponse(updatedNotice, Optional.empty());
    }

    @Transactional
    public NoticeResponse recordView(Long noticeId) {
        User currentUser = getCurrentUser();
        Notice notice = noticeRepository.findByIdWithTargets(noticeId)
                .orElseThrow(() -> new RuntimeException("Notice not found"));

        if (currentUser.getRole() != Role.ADMIN) {
            NoticeStatus status = noticeStatusRepository
                    .findByUserIdAndNoticeId(currentUser.getId(), noticeId)
                    .orElseGet(() -> NoticeStatus.builder()
                            .user(currentUser)
                            .notice(notice)
                            .isRead(false)
                            .isAcknowledged(false)
                            .viewed(false)
                            .build());
            if (!status.isViewed()) {
                status.setViewed(true);
                notice.setViewCount((notice.getViewCount() == null ? 0L : notice.getViewCount()) + 1);
                noticeStatusRepository.save(status);
                noticeRepository.save(notice);
            }
        }

        Optional<Notification> notification = currentUser.getRole() == Role.ADMIN
                ? Optional.empty()
                : notificationRepository.findFirstByNoticeIdAndUserIdOrderByIdAsc(noticeId, currentUser.getId());
        return toResponse(notice, notification);
    }

    @Transactional
    public NoticeReplyResponse addReply(Long noticeId, NoticeReplyRequest request) {
        User currentUser = getCurrentUser();
        if (currentUser.getRole() == Role.ADMIN) {
            throw new RuntimeException("Admins cannot reply to notices");
        }
        Notice notice = noticeRepository.findById(noticeId)
                .orElseThrow(() -> new RuntimeException("Notice not found"));
        NoticeReply reply = NoticeReply.builder()
                .notice(notice)
                .user(currentUser)
                .message(request.getMessage().trim())
                .build();
        return toReplyResponse(noticeReplyRepository.save(reply));
    }

    @Transactional(readOnly = true)
    public List<NoticeReplyResponse> getReplies(Long noticeId) {
        User currentUser = getCurrentUser();
        List<NoticeReply> replies = currentUser.getRole() == Role.ADMIN
                ? noticeReplyRepository.findByNoticeIdOrderByCreatedAtDesc(noticeId)
                : noticeReplyRepository.findByNoticeIdAndUserIdOrderByCreatedAtDesc(noticeId, currentUser.getId());
        return replies.stream().map(this::toReplyResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<ActivityItemResponse> getRecentActivity() {
        User currentUser = getCurrentUser();
        if (currentUser.getRole() != Role.ADMIN) {
            throw new RuntimeException("Only admins can view activity");
        }

        List<ActivityItemResponse> activity = new ArrayList<>();
        noticeRepository.findTop5ByOrderByCreatedAtDesc().forEach(notice ->
                activity.add(ActivityItemResponse.builder()
                        .type("NOTICE")
                        .noticeId(notice.getId())
                        .title("Notice published")
                        .message(notice.getTitle())
                        .createdAt(notice.getCreatedAt())
                        .build()));
        noticeReplyRepository.findTop5ByOrderByCreatedAtDesc().forEach(reply ->
                activity.add(ActivityItemResponse.builder()
                        .type("REPLY")
                        .noticeId(reply.getNotice().getId())
                        .title("Student reply")
                        .message(reply.getUser().getName() + ": " + reply.getMessage())
                        .createdAt(reply.getCreatedAt())
                        .build()));
        notificationRepository.findTop5ByIsAcknowledgedTrueOrderByCreatedAtDesc().forEach(notification ->
                activity.add(ActivityItemResponse.builder()
                        .type("ACKNOWLEDGEMENT")
                        .noticeId(notification.getNotice().getId())
                        .title("Notice acknowledged")
                        .message(notification.getUser().getName() + " acknowledged " + notification.getNotice().getTitle())
                        .createdAt(notification.getCreatedAt())
                        .build()));

        return activity.stream()
                .sorted(Comparator.comparing(ActivityItemResponse::getCreatedAt).reversed())
                .limit(10)
                .toList();
    }

    @Transactional
    public void deleteNotice(Long noticeId) {
        Notice notice = noticeRepository.findById(noticeId)
                .orElseThrow(() -> new RuntimeException("Notice not found"));
        noticeRepository.delete(notice);
    }

    private void applyTargets(Notice notice, NoticeRequest request) {
        notice.getTargets().clear();
        if (request.getTargets() == null || request.getTargets().isEmpty()) {
            // Empty targets means global notice; any user can view it.
            return;
        }
        for (var targetRequest : request.getTargets()) {
            NoticeTarget target = NoticeTarget.builder()
                    .notice(notice)
                    .department(targetRequest.getDepartment())
                    .year(targetRequest.getYear())
                    .build();
            notice.getTargets().add(target);
        }
    }

    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getName() == null) {
            throw new RuntimeException("Unauthenticated request");
        }

        return userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Authenticated user not found"));
    }

    private String normalizeCategory(String category) {
        if (category == null || category.trim().isEmpty()) {
            return "GENERAL";
        }
        return category.trim().toUpperCase();
    }

    private NoticeResponse toResponse(Notice notice, Optional<Notification> notificationOptional) {
        List<NoticeTargetResponse> targets = notice.getTargets().stream()
                .map(target -> NoticeTargetResponse.builder()
                        .id(target.getId())
                        .department(target.getDepartment())
                        .year(target.getYear())
                        .build())
                .collect(Collectors.toList());

        return NoticeResponse.builder()
                .id(notice.getId())
                .title(notice.getTitle())
                .description(notice.getDescription())
                .category(notice.getCategory())
                .priority(notice.getPriority())
                .pinned(notice.isPinned())
                .viewCount(notice.getViewCount() == null ? 0L : notice.getViewCount())
                .replyCount(noticeReplyRepository.countByNoticeId(notice.getId()))
                .createdAt(notice.getCreatedAt())
                .expiryDate(notice.getExpiryDate())
                .createdBy(notice.getCreatedBy().getEmail())
                .targets(targets)
                .notificationId(notificationOptional.map(Notification::getId).orElse(null))
                .isRead(notificationOptional.map(Notification::isRead).orElse(false))
                .isAcknowledged(notificationOptional.map(Notification::isAcknowledged).orElse(false))
                .build();
    }

    private NoticeReplyResponse toReplyResponse(NoticeReply reply) {
        return NoticeReplyResponse.builder()
                .id(reply.getId())
                .noticeId(reply.getNotice().getId())
                .userId(reply.getUser().getId())
                .userName(reply.getUser().getName())
                .userEmail(reply.getUser().getEmail())
                .message(reply.getMessage())
                .createdAt(reply.getCreatedAt())
                .build();
    }
}
