package com.findmyteam.modules.user.dto;

import com.findmyteam.modules.game.entity.Game;
import com.findmyteam.modules.user.entity.RankSource;
import com.findmyteam.modules.user.entity.RiotVerificationStatus;
import com.findmyteam.modules.user.entity.UserGameProfile;

import java.time.OffsetDateTime;
import java.util.UUID;

public record UserGameProfileResponse(
    UUID id,
    UUID gameId,
    String gameName,
    String rank,
    String verifiedRank,
    String rankSource,
    String role,
    boolean hasMic,
    boolean isPrimary,
    String riotGameName,
    String riotTagLine,
    String riotRegion,
    String riotVerificationStatus,
    boolean riotVerified,
    OffsetDateTime riotVerifiedAt,
    OffsetDateTime riotProfileLastSyncedAt
) {
    public static UserGameProfileResponse from(UserGameProfile profile, Game game) {
        String effectiveRank = profile.getRankSource() == RankSource.RIOT
            ? profile.getVerifiedRank()
            : profile.getRank();

        return new UserGameProfileResponse(
            profile.getId(),
            profile.getGameId(),
            game != null ? game.getName() : null,
            effectiveRank,
            profile.getVerifiedRank(),
            profile.getRankSource() != null ? profile.getRankSource().name() : RankSource.MANUAL.name(),
            profile.getRole(),
            profile.isHasMic(),
            profile.isPrimary(),
            profile.getRiotGameName(),
            profile.getRiotTagLine(),
            profile.getRiotRegion(),
            profile.getRiotVerificationStatus() != null ? profile.getRiotVerificationStatus().name() : RiotVerificationStatus.UNVERIFIED.name(),
            profile.getRiotVerificationStatus() == RiotVerificationStatus.VERIFIED,
            profile.getRiotVerifiedAt(),
            profile.getRiotProfileLastSyncedAt()
        );
    }
}
