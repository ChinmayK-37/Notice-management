package com.college.notice.analytics.service;

import com.college.notice.analytics.dto.AnalyticsResponse;
import com.college.notice.analytics.repository.NoticeStatusRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AnalyticsService {

    private final NoticeStatusRepository noticeStatusRepository;

    @Transactional(readOnly = true)
    public AnalyticsResponse getNoticeAnalytics(Long noticeId) {
        long totalUsers = noticeStatusRepository.countByNoticeId(noticeId);
        long readUsers = noticeStatusRepository.countByNoticeIdAndIsReadTrue(noticeId);
        long acknowledgedUsers = noticeStatusRepository.countByNoticeIdAndIsAcknowledgedTrue(noticeId);

        double readPercentage = totalUsers == 0 ? 0.0 : (readUsers * 100.0) / totalUsers;
        double acknowledgedPercentage = totalUsers == 0 ? 0.0 : (acknowledgedUsers * 100.0) / totalUsers;
        readPercentage = Math.round(readPercentage * 100.0) / 100.0;
        acknowledgedPercentage = Math.round(acknowledgedPercentage * 100.0) / 100.0;

        return AnalyticsResponse.builder()
                .totalUsers(totalUsers)
                .readPercentage(readPercentage)
                .acknowledgedPercentage(acknowledgedPercentage)
                .build();
    }
}
