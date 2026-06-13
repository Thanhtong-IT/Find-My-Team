package com.findmyteam.modules.match.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record CreateSwipeRequest(
    @NotNull(message = "Target ID là bắt buộc")
    UUID targetId,

    @NotNull(message = "Direction là bắt buộc")
    String direction,

    UUID gameId
) {}
