package com.findmyteam.modules.team.dto;

import com.findmyteam.modules.team.entity.JoinRequest;
import java.time.OffsetDateTime;
import java.util.UUID;

public record JoinRequestResponse(
    UUID id,
    UUID teamId,
    UUID userId,
    String username,
    String displayName,
    String avatarUrl,
    String message,
    String status,
    OffsetDateTime createdAt
) {
    public static JoinRequestResponse from(JoinRequest request) {
        return new JoinRequestResponse(
            request.getId(),
            request.getTeamId(),
            request.getUserId(),
            request.getUser() != null ? request.getUser().getUsername() : null,
            request.getUser() != null ? request.getUser().getDisplayName() : null,
            request.getUser() != null ? request.getUser().getAvatarUrl() : null,
            request.getMessage(),
            request.getStatus(),
            request.getCreatedAt()
        );
    }
}
