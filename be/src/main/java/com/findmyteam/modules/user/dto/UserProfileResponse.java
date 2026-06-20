package com.findmyteam.modules.user.dto;

import com.findmyteam.modules.auth.entity.User;
import com.findmyteam.modules.community.entity.CommunityMember;
import com.findmyteam.modules.user.entity.UserGameProfile;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

public record UserProfileResponse(
    UUID id,
    String email,
    String username,
    String fullName,
    String displayName,
    String avatarUrl,
    String bio,
    String region,
    List<UserGameProfileResponse> gameProfiles,
    TeamInfo currentTeam,
    List<CommunityInfo> communities,
    OffsetDateTime createdAt
) {
    public record TeamInfo(
        UUID id,
        String name,
        String gameName,
        String role,
        boolean isReady
    ) {}

    public record CommunityInfo(
        UUID id,
        String name,
        String gameName,
        String role
    ) {}

    public static UserProfileResponse from(User user, List<UserGameProfile> profiles, TeamInfo teamInfo, List<CommunityMember> userCommunities, java.util.function.Function<UUID, String> getCommunityName, java.util.function.Function<UUID, String> getGameName) {
        List<UserGameProfileResponse> profileResponses = profiles.stream()
            .map(p -> UserGameProfileResponse.from(p, p.getGame()))
            .toList();

        List<CommunityInfo> communityInfos = userCommunities.stream()
            .map(uc -> new CommunityInfo(uc.getCommunityId(), getCommunityName.apply(uc.getCommunityId()), getGameName.apply(uc.getCommunityId()), uc.getRole()))
            .toList();

        return new UserProfileResponse(
            user.getId(),
            user.getEmail(),
            user.getUsername(),
            user.getFullName(),
            user.getDisplayName(),
            user.getAvatarUrl(),
            user.getBio(),
            user.getRegion(),
            profileResponses,
            teamInfo,
            communityInfos,
            user.getCreatedAt()
        );
    }
}
