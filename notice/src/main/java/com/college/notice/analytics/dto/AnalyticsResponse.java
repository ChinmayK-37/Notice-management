package com.college.notice.analytics.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AnalyticsResponse {
    private long totalUsers;
    private long readCount;
    private long unreadCount;
    private long acknowledgedCount;
    private long viewCount;
    private long replyCount;
    private double readPercentage;
    private double acknowledgedPercentage;
}
