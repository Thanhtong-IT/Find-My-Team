package com.findmyteam.modules.notification.service;

import com.findmyteam.common.dto.PageResponse;
import com.findmyteam.common.event.EventPublisher;
import com.findmyteam.common.event.EventType;
import com.findmyteam.modules.notification.dto.NotificationResponse;
import com.findmyteam.modules.notification.entity.Notification;
import com.findmyteam.modules.notification.repository.NotificationRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final EventPublisher eventPublisher;

    public NotificationService(NotificationRepository notificationRepository,
                            EventPublisher eventPublisher) {
        this.notificationRepository = notificationRepository;
        this.eventPublisher = eventPublisher;
    }

    @Transactional(readOnly = true)
    public PageResponse<NotificationResponse> getNotifications(UUID userId, String type, Pageable pageable) {
        Page<Notification> notifications;
        if (type != null) {
            notifications = notificationRepository.findByUserIdAndTypeOrderByCreatedAtDesc(userId, type, pageable);
        } else {
            notifications = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
        }
        return PageResponse.from(notifications.map(NotificationResponse::from));
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(UUID userId) {
        return notificationRepository.countUnreadByUserId(userId);
    }

    @Transactional
    public void markAsRead(UUID userId, UUID notificationId) {
        notificationRepository.markAsRead(userId, notificationId);
    }

    @Transactional
    public void markAllAsRead(UUID userId) {
        notificationRepository.markAllAsRead(userId);
    }

    public void createNotification(UUID userId, String type, String title, String body,
                                  String actionId, String actionId2) {
        Notification notification = doCreateNotification(userId, type, title, body, actionId, actionId2);

        eventPublisher.publish(EventType.NOTIFICATION_NEW, Map.of(
            "userId", userId,
            "notificationId", notification.getId(),
            "type", type,
            "title", title
        ));
    }

    @Transactional
    protected Notification doCreateNotification(UUID userId, String type, String title, String body,
                                              String actionId, String actionId2) {
        Notification notification = new Notification();
        notification.setUserId(userId);
        notification.setType(type);
        notification.setTitle(title);
        notification.setBody(body);
        notification.setActionId(actionId);
        notification.setActionId2(actionId2);
        return notificationRepository.save(notification);
    }
}
