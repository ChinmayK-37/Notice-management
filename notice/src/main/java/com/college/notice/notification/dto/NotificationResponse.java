package com.college.notice.notification.dto;

import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationResponse {
    private Long id;
    private Long noticeId;
    private String message;
    private String type;
    private boolean isRead;
    private boolean isAcknowledged;
    private LocalDateTime createdAt;
}
