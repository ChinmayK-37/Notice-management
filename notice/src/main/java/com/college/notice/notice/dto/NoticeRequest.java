package com.college.notice.notice.dto;

import com.college.notice.notice.entity.Priority;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
public class NoticeRequest {

    @NotBlank(message = "Title is required")
    private String title;

    @NotBlank(message = "Description is required")
    private String description;

    private String category;

    @NotNull(message = "Priority is required")
    private Priority priority;

    private boolean pinned;

    @Future(message = "Expiry date must be in the future")
    private LocalDateTime expiryDate;

    @Valid
    private List<NoticeTargetRequest> targets;
}
