package com.college.notice.notice.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NoticeReplyRequest {

    @NotBlank(message = "Reply message is required")
    @Size(max = 1000, message = "Reply must be under 1000 characters")
    private String message;
}

