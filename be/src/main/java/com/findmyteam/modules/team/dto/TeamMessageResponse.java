package com.findmyteam.modules.team.dto;

import com.findmyteam.modules.team.entity.TeamMessage;
import java.time.OffsetDateTime;
import java.util.UUID;

public record TeamMessageResponse(
    UUID id,
    UUID teamId,
    UUID senderId,
    String senderName,
    String senderAvatar,
    String content,
    String imageUrl,
    String clientMessageId,
    OffsetDateTime createdAt
) {
    public static TeamMessageResponse from(TeamMessage message) {
        String senderName = null;
        String senderAvatar = null;
        if (message.getSender() != null) {
            senderName = message.getSender().getDisplayName();
            senderAvatar = message.getSender().getAvatarUrl();
        }

        return new TeamMessageResponse(
            message.getId(),
            message.getTeamId(),
            message.getSenderId(),
            senderName,
            senderAvatar,
            message.getContent(),
            message.getImageUrl(),
            message.getClientMessageId(),
            message.getCreatedAt()
        );
    }
}
