package com.college.notice.notice.controller;

import com.college.notice.notice.dto.NoticeRequest;
import com.college.notice.notice.dto.NoticeResponse;
import com.college.notice.notice.service.NoticeService;
import com.college.notice.shared.util.ApiResponse;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notices")
@RequiredArgsConstructor
public class NoticeController {

    private final NoticeService noticeService;

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<NoticeResponse>> createNotice(@Valid @RequestBody NoticeRequest request) {
        NoticeResponse response = noticeService.createNotice(request);
        return ResponseEntity.ok(
                ApiResponse.<NoticeResponse>builder()
                        .success(true)
                        .message("Notice created successfully")
                        .data(response)
                        .build()
        );
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<NoticeResponse>>> getNoticesForUser() {
        List<NoticeResponse> response = noticeService.getNoticesForUser();
        return ResponseEntity.ok(
                ApiResponse.<List<NoticeResponse>>builder()
                        .success(true)
                        .message("Notices fetched successfully")
                        .data(response)
                        .build()
        );
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<NoticeResponse>> updateNotice(
            @PathVariable("id") Long noticeId,
            @Valid @RequestBody NoticeRequest request
    ) {
        NoticeResponse response = noticeService.updateNotice(noticeId, request);
        return ResponseEntity.ok(
                ApiResponse.<NoticeResponse>builder()
                        .success(true)
                        .message("Notice updated successfully")
                        .data(response)
                        .build()
        );
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteNotice(@PathVariable("id") Long noticeId) {
        noticeService.deleteNotice(noticeId);
        return ResponseEntity.ok(
                ApiResponse.<Void>builder()
                        .success(true)
                        .message("Notice deleted successfully")
                        .data(null)
                        .build()
        );
    }
}
