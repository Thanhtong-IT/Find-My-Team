package com.findmyteam.modules.auth.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record AuthResponse(
    UUID userId,
    String email,
    String username,
    String fullName,
    String displayName,
    String avatarUrl,
    String accessToken,
    String refreshToken,
    OffsetDateTime accessTokenExpiresAt,
    OffsetDateTime refreshTokenExpiresAt
) {}
