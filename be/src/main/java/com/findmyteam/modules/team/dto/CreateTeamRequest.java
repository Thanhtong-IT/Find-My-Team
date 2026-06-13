package com.findmyteam.modules.team.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public record CreateTeamRequest(
    @JsonProperty("gameId")
    @NotNull(message = "Vui lòng chọn game")
    UUID gameId,

    @NotBlank(message = "Tên team không được để trống")
    @Size(max = 100, message = "Tên team tối đa 100 ký tự")
    @JsonProperty("name")
    String name,

    @JsonProperty("requiredRank")
    @Size(max = 50, message = "Rank tối đa 50 ký tự")
    String requiredRank,

    @JsonProperty("maxSize")
    @Min(value = 2, message = "Team tối thiểu 2 người")
    @Max(value = 10, message = "Team tối đa 10 người")
    int maxSize,

    @JsonProperty("requiredRoles")
    List<String> requiredRoles,

    @JsonProperty("requireMic")
    boolean requireMic,

    @JsonProperty("description")
    @Size(max = 1000, message = "Mô tả tối đa 1000 ký tự")
    String description
) {}
