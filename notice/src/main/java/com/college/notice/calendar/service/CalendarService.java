package com.college.notice.calendar.service;

import com.college.notice.notice.dto.NoticeResponse;
import com.college.notice.notice.service.NoticeService;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CalendarService {

    private static final String NO_EXPIRY_BUCKET = "NO_EXPIRY";
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE;

    private final NoticeService noticeService;

    @Transactional(readOnly = true)
    public Map<String, List<NoticeResponse>> getCalendarNoticesForCurrentUser() {
        List<NoticeResponse> notices = noticeService.getNoticesForUser();
        Map<String, List<NoticeResponse>> grouped = new TreeMap<>();

        for (NoticeResponse notice : notices) {
            if (notice.getExpiryDate() == null) {
                grouped.computeIfAbsent(NO_EXPIRY_BUCKET, key -> new java.util.ArrayList<>()).add(notice);
                continue;
            }

            LocalDate date = notice.getExpiryDate().toLocalDate();
            String key = date.format(DATE_FORMATTER);
            grouped.computeIfAbsent(key, ignored -> new java.util.ArrayList<>()).add(notice);
        }

        return grouped;
    }
}
