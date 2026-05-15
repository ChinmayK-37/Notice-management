package com.college.notice.notice.controller;

import com.college.notice.notice.dto.ActivityItemResponse;
import com.college.notice.notice.dto.NoticeRequest;
import com.college.notice.notice.dto.NoticeReplyRequest;
import com.college.notice.notice.dto.NoticeReplyResponse;
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

    @GetMapping("/activity")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<ActivityItemResponse>>> getRecentActivity() {
        List<ActivityItemResponse> response = noticeService.getRecentActivity();
        return ResponseEntity.ok(
                ApiResponse.<List<ActivityItemResponse>>builder()
                        .success(true)
                        .message("Recent activity fetched successfully")
                        .data(response)
                        .build()
        );
    }

    @GetMapping("/archived")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<NoticeResponse>>> getArchivedNotices() {
        List<NoticeResponse> response = noticeService.getArchivedNotices();
        return ResponseEntity.ok(
                ApiResponse.<List<NoticeResponse>>builder()
                        .success(true)
                        .message("Archived notices fetched successfully")
                        .data(response)
                        .build()
        );
    }

    @PostMapping("/{id}/view")
    public ResponseEntity<ApiResponse<NoticeResponse>> recordView(@PathVariable("id") Long noticeId) {
        NoticeResponse response = noticeService.recordView(noticeId);
        return ResponseEntity.ok(
                ApiResponse.<NoticeResponse>builder()
                        .success(true)
                        .message("Notice view recorded")
                        .data(response)
                        .build()
        );
    }

    @GetMapping("/{id}/replies")
    public ResponseEntity<ApiResponse<List<NoticeReplyResponse>>> getReplies(@PathVariable("id") Long noticeId) {
        List<NoticeReplyResponse> response = noticeService.getReplies(noticeId);
        return ResponseEntity.ok(
                ApiResponse.<List<NoticeReplyResponse>>builder()
                        .success(true)
                        .message("Replies fetched successfully")
                        .data(response)
                        .build()
        );
    }

    @PostMapping("/{id}/replies")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<NoticeReplyResponse>> addReply(
            @PathVariable("id") Long noticeId,
            @Valid @RequestBody NoticeReplyRequest request
    ) {
        NoticeReplyResponse response = noticeService.addReply(noticeId, request);
        return ResponseEntity.ok(
                ApiResponse.<NoticeReplyResponse>builder()
                        .success(true)
                        .message("Reply submitted successfully")
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

    @PostMapping("/{id}/archive")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<NoticeResponse>> archiveNotice(@PathVariable("id") Long noticeId) {
        NoticeResponse response = noticeService.archiveNotice(noticeId);
        return ResponseEntity.ok(
                ApiResponse.<NoticeResponse>builder()
                        .success(true)
                        .message("Notice archived successfully")
                        .data(response)
                        .build()
        );
    }

    @PostMapping("/{id}/restore")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<NoticeResponse>> restoreNotice(@PathVariable("id") Long noticeId) {
        NoticeResponse response = noticeService.restoreNotice(noticeId);
        return ResponseEntity.ok(
                ApiResponse.<NoticeResponse>builder()
                        .success(true)
                        .message("Notice restored successfully")
                        .data(response)
                        .build()
        );
    }
}
