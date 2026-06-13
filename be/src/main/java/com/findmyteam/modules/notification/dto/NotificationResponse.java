package com.findmyteam.modules.notification.dto;

import com.findmyteam.modules.notification.entity.Notification;
import java.time.OffsetDateTime;
import java.util.UUID;

public record NotificationResponse(
    UUID id,
    String type,
    String title,
    String body,
    boolean isRead,
    String actionId,
    String actionId2,
    OffsetDateTime createdAt
) {
    public static NotificationResponse from(Notification notification) {
        return new NotificationResponse(
            notification.getId(),
            notification.getType(),
            notification.getTitle(),
            notification.getBody(),
            notification.isRead(),
            notification.getActionId(),
            notification.getActionId2(),
            notification.getCreatedAt()
        );
    }
}
