package com.findmyteam.modules.team.dto;

import com.findmyteam.modules.team.entity.TeamRequest;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record TeamRequestResponse(
    UUID id,
    UUID userId,
    String username,
    String displayName,
    String avatarUrl,
    UUID gameId,
    String gameName,
    String requiredRank,
    List<String> requiredRoles,
    boolean requireMic,
    String description,
    String status,
    OffsetDateTime createdAt
) {
    public static TeamRequestResponse from(TeamRequest request) {
        return new TeamRequestResponse(
            request.getId(),
            request.getUserId(),
            request.getUser() != null ? request.getUser().getUsername() : null,
            request.getUser() != null ? request.getUser().getDisplayName() : null,
            request.getUser() != null ? request.getUser().getAvatarUrl() : null,
            request.getGameId(),
            request.getGame() != null ? request.getGame().getName() : null,
            request.getRequiredRank(),
            request.getRequiredRoles(),
            request.isRequireMic(),
            request.getDescription(),
            request.getStatus(),
            request.getCreatedAt()
        );
    }
}
