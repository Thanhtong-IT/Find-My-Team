package com.findmyteam.modules.user.dto;

import com.findmyteam.modules.user.entity.UserGameProfile;
import com.findmyteam.modules.game.entity.Game;
import java.util.UUID;

public record UserGameProfileResponse(
    UUID id,
    UUID gameId,
    String gameName,
    String rank,
    String role,
    boolean hasMic,
    boolean isPrimary
) {
    public static UserGameProfileResponse from(UserGameProfile profile, Game game) {
        return new UserGameProfileResponse(
            profile.getId(),
            profile.getGameId(),
            game != null ? game.getName() : null,
            profile.getRank(),
            profile.getRole(),
            profile.isHasMic(),
            profile.isPrimary()
        );
    }
}
