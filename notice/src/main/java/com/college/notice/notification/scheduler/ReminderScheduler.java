package com.college.notice.notification.scheduler;

import com.college.notice.analytics.entity.NoticeStatus;
import com.college.notice.analytics.repository.NoticeStatusRepository;
import com.college.notice.notice.entity.Notice;
import com.college.notice.notice.repository.NoticeRepository;
import com.college.notice.notification.entity.Notification;
import com.college.notice.notification.repository.NotificationRepository;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
@Slf4j
public class ReminderScheduler {

    private final NoticeRepository noticeRepository;
    private final NoticeStatusRepository noticeStatusRepository;
    private final NotificationRepository notificationRepository;

    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void sendDeadlineReminders() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime next24Hours = now.plusHours(24);

        List<Notice> expiringNotices = noticeRepository.findNoticesExpiringBetween(now, next24Hours);
        for (Notice notice : expiringNotices) {
            if (notice.getExpiryDate() == null || !notice.getExpiryDate().isAfter(now) || notice.getExpiryDate().isAfter(next24Hours)) {
                continue;
            }

            String reminderMessage = "Reminder: " + notice.getTitle() + " deadline approaching";
            List<NoticeStatus> unreadStatuses = noticeStatusRepository.findUnreadStatusesByNoticeId(notice.getId());

            List<Notification> reminders = new ArrayList<>();
            for (NoticeStatus status : unreadStatuses) {
                if (notificationRepository.existsByUserAndNoticeAndType(status.getUser(), notice, "REMINDER")) {
                    continue;
                }

                reminders.add(Notification.builder()
                        .user(status.getUser())
                        .notice(notice)
                        .message(reminderMessage)
                        .type("REMINDER")
                        .isRead(false)
                        .isAcknowledged(false)
                        .build());
            }

            if (!reminders.isEmpty()) {
                notificationRepository.saveAll(reminders);
                log.info("Created {} deadline reminders for noticeId={}", reminders.size(), notice.getId());
            }
        }
    }
}
