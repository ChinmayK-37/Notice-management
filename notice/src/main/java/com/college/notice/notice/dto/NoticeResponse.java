package com.college.notice.notice.dto;

import com.college.notice.notice.entity.Priority;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NoticeResponse {
    private Long id;
    private String title;
    private String description;
    private String category;
    private Priority priority;
    private boolean pinned;
    private Long viewCount;
    private Long replyCount;
    private LocalDateTime createdAt;
    private LocalDateTime expiryDate;
    private String createdBy;
    private List<NoticeTargetResponse> targets;
    @JsonProperty("notificationId")
    private Long notificationId;
    @JsonProperty("isRead")
    private boolean isRead;
    @JsonProperty("isAcknowledged")
    private boolean isAcknowledged;
}
