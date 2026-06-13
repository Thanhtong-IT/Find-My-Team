package com.findmyteam.modules.auth.dto;

import com.findmyteam.modules.auth.entity.User;
import com.findmyteam.modules.user.dto.UserGameProfileResponse;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record UserResponse(
    UUID id,
    String email,
    String username,
    String fullName,
    String displayName,
    String avatarUrl,
    String bio,
    String region,
    List<UserGameProfileResponse> gameProfiles,
    OffsetDateTime createdAt
) {
    public static UserResponse from(User user) {
        return new UserResponse(
            user.getId(),
            user.getEmail(),
            user.getUsername(),
            user.getFullName(),
            user.getDisplayName(),
            user.getAvatarUrl(),
            user.getBio(),
            user.getRegion(),
            List.of(),
            user.getCreatedAt()
        );
    }
}
