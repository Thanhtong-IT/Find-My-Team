package com.findmyteam.modules.user.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record GameProfileUpsertRequest(
    UUID id,

    @NotNull(message = "Game ID là bắt buộc")
    UUID gameId,

    String rank,

    String role,

    boolean hasMic,

    boolean isPrimary
) {}
