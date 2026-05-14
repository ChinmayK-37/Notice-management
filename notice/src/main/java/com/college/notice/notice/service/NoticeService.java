package com.college.notice.notice.service;

import com.college.notice.auth.entity.User;
import com.college.notice.auth.repository.UserRepository;
import com.college.notice.notice.dto.NoticeRequest;
import com.college.notice.notice.dto.NoticeResponse;
import com.college.notice.notice.dto.NoticeTargetResponse;
import com.college.notice.notice.entity.Notice;
import com.college.notice.notice.entity.NoticeTarget;
import com.college.notice.notice.event.NoticeCreatedEvent;
import com.college.notice.notice.config.NoticeExpiryPolicy;
import com.college.notice.notice.repository.NoticeRepository;
import com.college.notice.notification.entity.Notification;
import com.college.notice.notification.repository.NotificationRepository;
import java.time.LocalDateTime;
import java.util.ArrayList;
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

    @Transactional
    public NoticeResponse createNotice(NoticeRequest request) {
        User currentUser = getCurrentUser();

        Notice notice = Notice.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .priority(request.getPriority())
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
        List<Notice> notices = noticeRepository.findActiveNoticesVisibleForUser(
                currentUser.getDepartment(),
                currentUser.getYear(),
                noticeExpiryPolicy.visibilityCutoff()
        );

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
        notice.setPriority(request.getPriority());
        notice.setExpiryDate(request.getExpiryDate());
        applyTargets(notice, request);

        Notice updatedNotice = noticeRepository.save(notice);
        return toResponse(updatedNotice, Optional.empty());
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
                .priority(notice.getPriority())
                .createdAt(notice.getCreatedAt())
                .expiryDate(notice.getExpiryDate())
                .createdBy(notice.getCreatedBy().getEmail())
                .targets(targets)
                .notificationId(notificationOptional.map(Notification::getId).orElse(null))
                .isRead(notificationOptional.map(Notification::isRead).orElse(false))
                .isAcknowledged(notificationOptional.map(Notification::isAcknowledged).orElse(false))
                .build();
    }
}
