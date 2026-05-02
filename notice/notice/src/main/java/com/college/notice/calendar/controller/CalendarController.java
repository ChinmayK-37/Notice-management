package com.college.notice.calendar.controller;

import com.college.notice.calendar.service.CalendarService;
import com.college.notice.notice.dto.NoticeResponse;
import com.college.notice.shared.util.ApiResponse;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.security.access.prepost.PreAuthorize;

@RestController
@RequestMapping("/api/calendar")
@RequiredArgsConstructor
public class CalendarController {

    private final CalendarService calendarService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'STUDENT')")
    public ResponseEntity<ApiResponse<Map<String, List<NoticeResponse>>>> getCalendarView() {
        Map<String, List<NoticeResponse>> response = calendarService.getCalendarNoticesForCurrentUser();
        return ResponseEntity.ok(
                ApiResponse.<Map<String, List<NoticeResponse>>>builder()
                        .success(true)
                        .message("Calendar notices fetched successfully")
                        .data(response)
                        .build()
        );
    }
}
