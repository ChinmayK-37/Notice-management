package com.college.notice.analytics.controller;

import com.college.notice.analytics.dto.AnalyticsResponse;
import com.college.notice.analytics.service.AnalyticsService;
import com.college.notice.shared.util.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    @GetMapping("/{noticeId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<AnalyticsResponse>> getNoticeAnalytics(@PathVariable("noticeId") Long noticeId) {
        AnalyticsResponse response = analyticsService.getNoticeAnalytics(noticeId);
        return ResponseEntity.ok(
                ApiResponse.<AnalyticsResponse>builder()
                        .success(true)
                        .message("Analytics fetched successfully")
                        .data(response)
                        .build()
        );
    }
}
