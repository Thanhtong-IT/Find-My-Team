package com.findmyteam.modules.chat.dto;

import com.findmyteam.modules.chat.entity.Message;
import java.time.OffsetDateTime;
import java.util.UUID;

public record MessageResponse(
    UUID id,
    UUID channelId,
    UUID senderId,
    String senderUsername,
    String senderDisplayName,
    String senderAvatarUrl,
    String content,
    String imageUrl,
    String clientMessageId,
    OffsetDateTime createdAt
) {
    public static MessageResponse from(Message message) {
        return new MessageResponse(
            message.getId(),
            message.getChannelId(),
            message.getSenderId(),
            message.getSender() != null ? message.getSender().getUsername() : null,
            message.getSender() != null ? message.getSender().getDisplayName() : null,
            message.getSender() != null ? message.getSender().getAvatarUrl() : null,
            message.getContent(),
            message.getImageUrl(),
            message.getClientMessageId(),
            message.getCreatedAt()
        );
    }
}
