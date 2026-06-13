package com.findmyteam.modules.notification.controller;

import com.findmyteam.common.dto.ApiResponse;
import com.findmyteam.modules.notification.dto.NotificationResponse;
import com.findmyteam.modules.notification.service.NotificationService;
import com.findmyteam.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
@Tag(name = "Notifications", description = "APIs thông báo")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @Operation(summary = "Lấy danh sách thông báo")
    @GetMapping
    public ApiResponse<java.util.List<NotificationResponse>> getNotifications(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) String type,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.success(
            notificationService.getNotifications(principal.getId(), type, pageable).content()
        );
    }

    @Operation(summary = "Lấy số thông báo chưa đọc")
    @GetMapping("/unread-count")
    public ApiResponse<Long> getUnreadCount(@AuthenticationPrincipal UserPrincipal principal) {
        return ApiResponse.success(notificationService.getUnreadCount(principal.getId()));
    }

    @Operation(summary = "Đánh dấu thông báo đã đọc")
    @PutMapping("/{notificationId}/read")
    public ApiResponse<Void> markAsRead(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID notificationId) {
        notificationService.markAsRead(principal.getId(), notificationId);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Đánh dấu tất cả thông báo đã đọc")
    @PutMapping("/read-all")
    public ApiResponse<Void> markAllAsRead(@AuthenticationPrincipal UserPrincipal principal) {
        notificationService.markAllAsRead(principal.getId());
        return ApiResponse.success(null);
    }
}
