package com.findmyteam.modules.user.dto;

import jakarta.validation.constraints.NotBlank;

public record VerifyRiotAccountRequest(
    @NotBlank(message = "Riot ID game name là bắt buộc")
    String riotGameName,

    @NotBlank(message = "Riot ID tag line là bắt buộc")
    String riotTagLine,

    @NotBlank(message = "Region Riot là bắt buộc")
    String region
) {}
