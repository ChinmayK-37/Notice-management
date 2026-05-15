package com.college.notice.analytics.listener;

import com.college.notice.analytics.entity.NoticeStatus;
import com.college.notice.analytics.repository.NoticeStatusRepository;
import com.college.notice.auth.entity.User;
import com.college.notice.auth.repository.UserRepository;
import com.college.notice.notice.entity.Notice;
import com.college.notice.notice.entity.NoticeTarget;
import com.college.notice.notice.event.NoticeCreatedEvent;
import com.college.notice.notice.repository.NoticeRepository;
import com.college.notice.shared.constants.Role;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@Slf4j
@RequiredArgsConstructor
public class AnalyticsListener {

    private final NoticeRepository noticeRepository;
    private final UserRepository userRepository;
    private final NoticeStatusRepository noticeStatusRepository;

    @EventListener
    @Transactional
    public void onNoticeCreated(NoticeCreatedEvent event) {
        Notice notice = noticeRepository.findByIdWithTargets(event.getNoticeId())
                .orElseThrow(() -> new RuntimeException("Notice not found for analytics initialization"));

        List<User> recipients = resolveRecipients(notice);
        if (recipients.isEmpty()) {
            return;
        }

        List<NoticeStatus> statuses = recipients.stream()
                .map(user -> NoticeStatus.builder()
                        .user(user)
                        .notice(notice)
                        .isRead(false)
                        .isAcknowledged(false)
                        .viewed(false)
                        .build())
                .toList();

        noticeStatusRepository.saveAll(statuses);
        log.info("Initialized analytics status for noticeId={} recipients={}", event.getNoticeId(), statuses.size());
    }

    private List<User> resolveRecipients(Notice notice) {
        if (notice.getTargets() == null || notice.getTargets().isEmpty()) {
            return userRepository.findAll().stream()
                    .filter(user -> user.getRole() == Role.STUDENT)
                    .toList();
        }

        LinkedHashMap<Long, User> recipients = new LinkedHashMap<>();
        for (NoticeTarget target : notice.getTargets()) {
            List<User> users = userRepository.findByDepartmentAndYear(target.getDepartment(), target.getYear());
            for (User user : users) {
                if (user.getRole() == Role.STUDENT && targetMatchesUser(target, user)) {
                    recipients.putIfAbsent(user.getId(), user);
                }
            }
        }
        return new ArrayList<>(recipients.values());
    }

    private boolean targetMatchesUser(NoticeTarget target, User user) {
        return matchesOptional(target.getDivision(), user.getDivision())
                && matchesOptional(target.getBatch(), user.getBatch());
    }

    private boolean matchesOptional(String targetValue, String userValue) {
        if (targetValue == null || targetValue.trim().isEmpty()) {
            return true;
        }
        if (userValue == null || userValue.trim().isEmpty()) {
            return true;
        }
        return targetValue.equalsIgnoreCase(userValue);
    }
}
