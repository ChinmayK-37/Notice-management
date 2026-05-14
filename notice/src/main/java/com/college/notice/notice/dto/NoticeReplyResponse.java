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
public class NoticeReplyResponse {
    private Long id;
    private Long noticeId;
    private Long userId;
    private String userName;
    private String userEmail;
    private String message;
    private LocalDateTime createdAt;
}

