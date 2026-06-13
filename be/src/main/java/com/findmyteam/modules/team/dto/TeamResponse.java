package com.findmyteam.modules.team.dto;

import com.findmyteam.modules.team.entity.Team;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record TeamResponse(
    UUID id,
    String name,
    UUID gameId,
    String gameName,
    String requiredRank,
    int maxSize,
    int currentMemberCount,
    String description,
    List<String> requiredRoles,
    boolean requireMic,
    String status,
    OffsetDateTime createdAt
) {
    public static TeamResponse from(Team team, int memberCount, String gameName) {
        return new TeamResponse(
            team.getId(),
            team.getName(),
            team.getGameId(),
            gameName,
            team.getRequiredRank(),
            team.getMaxSize(),
            memberCount,
            team.getDescription(),
            team.getRequiredRoles(),
            team.isRequireMic(),
            team.getStatus(),
            team.getCreatedAt()
        );
    }
}
