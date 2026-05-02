package com.college.notice.notification.listener;

import com.college.notice.notice.entity.Notice;
import com.college.notice.notice.event.NoticeCreatedEvent;
import com.college.notice.notice.repository.NoticeRepository;
import com.college.notice.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
public class NotificationListener {

    private final NoticeRepository noticeRepository;
    private final NotificationService notificationService;

    @EventListener
    @Transactional
    public void onNoticeCreated(NoticeCreatedEvent event) {
        Notice notice = noticeRepository.findByIdWithTargets(event.getNoticeId())
                .orElseThrow(() -> new RuntimeException("Notice not found for notification creation"));
        notificationService.createNotificationsForNotice(notice);
    }
}
