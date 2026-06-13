package com.findmyteam.modules.explore.dto;

import com.findmyteam.modules.auth.entity.User;
import com.findmyteam.modules.user.entity.UserGameProfile;
import java.util.List;
import java.util.UUID;

public record OnlinePlayerResponse(
    UUID id,
    String username,
    String displayName,
    String avatarUrl,
    List<String> games,
    boolean hasMic
) {
    public static OnlinePlayerResponse from(User user, List<UserGameProfile> profiles) {
        List<String> games = profiles.stream()
            .map(p -> p.getGame() != null ? p.getGame().getName() : null)
            .filter(g -> g != null)
            .toList();

        boolean hasMic = profiles.stream().anyMatch(UserGameProfile::isHasMic);

        return new OnlinePlayerResponse(
            user.getId(),
            user.getUsername(),
            user.getDisplayName(),
            user.getAvatarUrl(),
            games,
            hasMic
        );
    }
}
