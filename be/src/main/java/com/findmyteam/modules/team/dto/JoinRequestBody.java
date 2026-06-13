package com.findmyteam.modules.team.dto;

import jakarta.validation.constraints.Size;

public record JoinRequestBody(
    @Size(max = 500, message = "Tin nhắn tối đa 500 ký tự")
    String message
) {}
