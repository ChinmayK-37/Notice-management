package com.college.notice.notification.controller;

import com.college.notice.notification.dto.NotificationResponse;
import com.college.notice.notification.service.NotificationService;
import com.college.notice.shared.util.ApiResponse;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<NotificationResponse>>> getUserNotifications(
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size
    ) {
        List<NotificationResponse> data = notificationService.getUserNotifications(PageRequest.of(page, size));
        return ResponseEntity.ok(
                ApiResponse.<List<NotificationResponse>>builder()
                        .success(true)
                        .message("Notifications fetched successfully")
                        .data(data)
                        .build()
        );
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<ApiResponse<NotificationResponse>> markAsRead(@PathVariable("id") Long notificationId) {
        NotificationResponse data = notificationService.markAsRead(notificationId);
        return ResponseEntity.ok(
                ApiResponse.<NotificationResponse>builder()
                        .success(true)
                        .message("Notification marked as read")
                        .data(data)
                        .build()
        );
    }

    @PutMapping("/{id}/acknowledge")
    public ResponseEntity<ApiResponse<NotificationResponse>> acknowledge(@PathVariable("id") Long notificationId) {
        NotificationResponse data = notificationService.acknowledge(notificationId);
        return ResponseEntity.ok(
                ApiResponse.<NotificationResponse>builder()
                        .success(true)
                        .message("Notification acknowledged")
                        .data(data)
                        .build()
        );
    }
}
