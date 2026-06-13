package com.findmyteam.modules.game.dto;

import com.findmyteam.modules.game.entity.Game;

import java.util.List;
import java.util.UUID;

public record GameResponse(
    UUID id,
    String name,
    String shortName,
    String tag,
    String gradientStart,
    String gradientEnd,
    String iconUrl,
    List<String> ranks,
    List<String> roles,
    int maxTeamSize,
    boolean isActive,
    Long activeTeamCount,
    Long openRequestCount
) {
    public static GameResponse from(Game game) {
        return new GameResponse(
            game.getId(),
            game.getName(),
            game.getShortName(),
            game.getTag(),
            game.getGradientStart(),
            game.getGradientEnd(),
            game.getIconUrl(),
            game.getRanks(),
            game.getRoles(),
            game.getMaxTeamSize(),
            game.isActive(),
            null,
            null
        );
    }

    public static GameResponse fromWithStats(Game game, Long teamCount, Long requestCount) {
        return new GameResponse(
            game.getId(),
            game.getName(),
            game.getShortName(),
            game.getTag(),
            game.getGradientStart(),
            game.getGradientEnd(),
            game.getIconUrl(),
            game.getRanks(),
            game.getRoles(),
            game.getMaxTeamSize(),
            game.isActive(),
            teamCount,
            requestCount
        );
    }
}
