package com.findmyteam.modules.team.dto;

import com.findmyteam.modules.team.entity.Team;
import com.findmyteam.modules.team.entity.TeamMember;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record TeamDetailResponse(
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
    UUID ownerId,
    List<MemberInfo> members,
    OffsetDateTime createdAt
) {
    public record MemberInfo(
        UUID id,
        UUID userId,
        String username,
        String displayName,
        String avatarUrl,
        String role,
        boolean isReady
    ) {}

    public static TeamDetailResponse from(Team team, List<TeamMember> members, String gameName) {
        List<MemberInfo> memberInfos = members.stream()
            .map(m -> new MemberInfo(
                m.getId(),
                m.getUserId(),
                m.getUser() != null ? m.getUser().getUsername() : null,
                m.getUser() != null ? m.getUser().getDisplayName() : null,
                m.getUser() != null ? m.getUser().getAvatarUrl() : null,
                m.getRole(),
                m.isReady()
            ))
            .toList();

        return new TeamDetailResponse(
            team.getId(),
            team.getName(),
            team.getGameId(),
            gameName,
            team.getRequiredRank(),
            team.getMaxSize(),
            members.size(),
            team.getDescription(),
            team.getRequiredRoles(),
            team.isRequireMic(),
            team.getStatus(),
            team.getOwnerId(),
            memberInfos,
            team.getCreatedAt()
        );
    }
}
