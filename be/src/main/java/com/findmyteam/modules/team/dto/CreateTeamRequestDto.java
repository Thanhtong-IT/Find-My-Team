package com.findmyteam.modules.team.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public record CreateTeamRequestDto(
    @NotNull(message = "Game ID là bắt buộc")
    UUID gameId,

    @Min(value = 2, message = "Team tối thiểu 2 người")
    @Max(value = 10, message = "Team tối đa 10 người")
    int maxSize,

    @Size(max = 50, message = "Rank tối đa 50 ký tự")
    String requiredRank,

    List<String> requiredRoles,

    boolean requireMic,

    @Size(max = 1000, message = "Mô tả tối đa 1000 ký tự")
    String description
) {}
