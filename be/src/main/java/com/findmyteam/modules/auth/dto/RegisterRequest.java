package com.findmyteam.modules.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
    @NotBlank(message = "Email là bắt buộc")
    @Email(message = "Email không hợp lệ")
    String email,

    @NotBlank(message = "Username là bắt buộc")
    @Size(min = 3, max = 50, message = "Username phải từ 3-50 ký tự")
    String username,

    @NotBlank(message = "Họ tên là bắt buộc")
    @Size(min = 2, max = 100, message = "Họ tên phải từ 2-100 ký tự")
    String fullName,

    @NotBlank(message = "Mật khẩu là bắt buộc")
    @Size(min = 6, message = "Mật khẩu phải có ít nhất 6 ký tự")
    String password
) {}
