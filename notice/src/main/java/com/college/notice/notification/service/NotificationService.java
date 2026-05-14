package com.college.notice.notification.service;

import com.college.notice.analytics.repository.NoticeStatusRepository;
import com.college.notice.auth.entity.User;
import com.college.notice.auth.repository.UserRepository;
import com.college.notice.notice.entity.Notice;
import com.college.notice.notice.entity.NoticeTarget;
import com.college.notice.notification.dto.NotificationResponse;
import com.college.notice.notification.entity.Notification;
import com.college.notice.notification.repository.NotificationRepository;
import org.springframework.data.domain.Pageable;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final NoticeStatusRepository noticeStatusRepository;
    private final UserRepository userRepository;

    @Transactional
    public void createNotificationsForNotice(Notice notice) {
        List<User> recipients = resolveRecipients(notice);
        if (recipients.isEmpty()) {
            return;
        }

        List<Notification> notifications = new ArrayList<>();
        for (User user : recipients) {
            if (notificationRepository.existsByUserAndNoticeAndType(user, notice, "NORMAL")) {
                continue;
            }
            notifications.add(Notification.builder()
                    .user(user)
                    .notice(notice)
                    .message("New notice published: " + notice.getTitle())
                    .type("NORMAL")
                    .isRead(false)
                    .isAcknowledged(false)
                    .build());
        }
        notificationRepository.saveAll(notifications);
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> getUserNotifications(Pageable pageable) {
        User currentUser = getCurrentUser();
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(currentUser.getId(), pageable)
                .getContent()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public NotificationResponse markAsRead(Long notificationId) {
        User currentUser = getCurrentUser();
        Notification notification = notificationRepository.findByIdAndUserId(notificationId, currentUser.getId())
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        notification.setRead(true);
        Notification savedNotification = notificationRepository.save(notification);
        noticeStatusRepository.findByUserIdAndNoticeId(currentUser.getId(), notification.getNotice().getId())
                .ifPresent(status -> {
                    status.setRead(true);
                    noticeStatusRepository.save(status);
                });
        return toResponse(savedNotification);
    }

    @Transactional
    public NotificationResponse acknowledge(Long notificationId) {
        User currentUser = getCurrentUser();
        Notification notification = notificationRepository.findByIdAndUserId(notificationId, currentUser.getId())
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        notification.setAcknowledged(true);
        Notification savedNotification = notificationRepository.save(notification);
        noticeStatusRepository.findByUserIdAndNoticeId(currentUser.getId(), notification.getNotice().getId())
                .ifPresent(status -> {
                    status.setAcknowledged(true);
                    noticeStatusRepository.save(status);
                });
        return toResponse(savedNotification);
    }

    private List<User> resolveRecipients(Notice notice) {
        if (notice.getTargets() == null || notice.getTargets().isEmpty()) {
            return userRepository.findAll();
        }

        LinkedHashMap<Long, User> recipients = new LinkedHashMap<>();
        for (NoticeTarget target : notice.getTargets()) {
            List<User> users = userRepository.findByDepartmentAndYear(target.getDepartment(), target.getYear());
            for (User user : users) {
                recipients.putIfAbsent(user.getId(), user);
            }
        }
        return new ArrayList<>(recipients.values());
    }

    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new RuntimeException("Unauthenticated request");
        }

        Object principal = authentication.getPrincipal();
        String email;
        if (principal instanceof User userPrincipal) {
            return userPrincipal;
        } else if (principal instanceof UserDetails userDetails) {
            email = userDetails.getUsername();
        } else {
            email = authentication.getName();
        }

        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Authenticated user not found"));
    }

    private NotificationResponse toResponse(Notification notification) {
        return NotificationResponse.builder()
                .id(notification.getId())
                .noticeId(notification.getNotice().getId())
                .message(notification.getMessage())
                .type(notification.getType())
                .isRead(notification.isRead())
                .isAcknowledged(notification.isAcknowledged())
                .createdAt(notification.getCreatedAt())
                .build();
    }
}
