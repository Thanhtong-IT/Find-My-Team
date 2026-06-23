package com.findmyteam.modules.user.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

import java.util.List;

public record UpdateGameProfilesRequest(
    @NotNull(message = "Danh sách game profile là bắt buộc")
    @Valid
    List<GameProfileUpsertRequest> profiles
) {}
