package com.findmyteam.modules.user.dto;

import jakarta.validation.constraints.NotBlank;

public record AvatarUploadUrlRequest(
    @NotBlank(message = "Content type là bắt buộc")
    String contentType
) {}
