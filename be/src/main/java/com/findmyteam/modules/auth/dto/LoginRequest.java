package com.findmyteam.modules.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
    @NotBlank(message = "Email là bắt buộc")
    @Email(message = "Email không hợp lệ")
    String email,

    @NotBlank(message = "Mật khẩu là bắt buộc")
    String password
) {}
