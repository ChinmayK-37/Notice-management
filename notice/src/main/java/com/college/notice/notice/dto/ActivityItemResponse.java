package com.college.notice.notice.dto;

import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ActivityItemResponse {
    private String type;
    private Long noticeId;
    private String title;
    private String message;
    private LocalDateTime createdAt;
}

