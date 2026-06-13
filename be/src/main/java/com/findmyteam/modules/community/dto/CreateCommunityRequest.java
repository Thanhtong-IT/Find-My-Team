package com.findmyteam.modules.community.dto;

import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateCommunityRequest(
    @Size(max = 100, message = "Tên cộng đồng tối đa 100 ký tự")
    String name,

    UUID gameId,

    @Size(max = 1000, message = "Mô tả tối đa 1000 ký tự")
    String description,

    @Size(max = 500, message = "Avatar URL tối đa 500 ký tự")
    String avatarUrl,

    boolean isPublic
) {}
