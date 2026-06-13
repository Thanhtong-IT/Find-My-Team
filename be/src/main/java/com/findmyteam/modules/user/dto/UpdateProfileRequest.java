package com.findmyteam.modules.user.dto;

import jakarta.validation.constraints.Size;

public record UpdateProfileRequest(
    @Size(max = 100, message = "Display name tối đa 100 ký tự")
    String displayName,

    @Size(max = 500, message = "Avatar URL tối đa 500 ký tự")
    String avatarUrl,

    @Size(max = 1000, message = "Bio tối đa 1000 ký tự")
    String bio,

    @Size(max = 50, message = "Region tối đa 50 ký tự")
    String region
) {}
