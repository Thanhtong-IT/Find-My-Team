package com.findmyteam.modules.match.dto;

import com.findmyteam.modules.match.entity.Match;
import com.findmyteam.modules.auth.entity.User;
import java.time.OffsetDateTime;
import java.util.UUID;

public record MatchResponse(
    UUID id,
    UUID userAId,
    String userAUsername,
    String userADisplayName,
    String userAAvatarUrl,
    UUID userBId,
    String userBUsername,
    String userBDisplayName,
    String userBAvatarUrl,
    UUID gameId,
    OffsetDateTime createdAt
) {
    public static MatchResponse from(Match match) {
        User userA = match.getUserA();
        User userB = match.getUserB();

        return new MatchResponse(
            match.getId(),
            match.getUserAId(),
            userA != null ? userA.getUsername() : null,
            userA != null ? userA.getDisplayName() : null,
            userA != null ? userA.getAvatarUrl() : null,
            match.getUserBId(),
            userB != null ? userB.getUsername() : null,
            userB != null ? userB.getDisplayName() : null,
            userB != null ? userB.getAvatarUrl() : null,
            match.getGameId(),
            match.getCreatedAt()
        );
    }
}
