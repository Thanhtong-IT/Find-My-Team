package com.findmyteam.modules.user.dto;

public record AvatarUploadUrlResponse(
    String uploadUrl,
    String publicUrl,
    String objectKey,
    long expiresInSeconds
) {}
