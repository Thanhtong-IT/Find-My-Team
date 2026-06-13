package com.findmyteam.modules.community.dto;

import com.findmyteam.modules.community.entity.Community;
import java.time.OffsetDateTime;
import java.util.UUID;

public record CommunityResponse(
    UUID id,
    String name,
    UUID gameId,
    String gameName,
    String description,
    String avatarUrl,
    boolean isPublic,
    UUID ownerId,
    String ownerName,
    int memberCount,
    OffsetDateTime createdAt
) {
    public static CommunityResponse from(Community community, String gameName, String ownerName) {
        return new CommunityResponse(
            community.getId(),
            community.getName(),
            community.getGameId(),
            gameName,
            community.getDescription(),
            community.getAvatarUrl(),
            community.isPublic(),
            community.getOwnerId(),
            ownerName,
            community.getMemberCount(),
            community.getCreatedAt()
        );
    }
}
