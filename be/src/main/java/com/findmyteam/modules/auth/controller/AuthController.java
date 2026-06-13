package com.findmyteam.modules.auth.controller;

import com.findmyteam.common.dto.ApiResponse;
import com.findmyteam.modules.auth.dto.AuthResponse;
import com.findmyteam.modules.auth.dto.LoginRequest;
import com.findmyteam.modules.auth.dto.RefreshTokenRequest;
import com.findmyteam.modules.auth.dto.RegisterRequest;
import com.findmyteam.modules.auth.service.AuthService;
import com.findmyteam.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "APIs đăng ký, đăng nhập, quản lý token")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @Operation(summary = "Đăng ký tài khoản mới")
    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ApiResponse.success(authService.register(request));
    }

    @Operation(summary = "Đăng nhập")
    @PostMapping("/login")
    public ApiResponse<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.success(authService.login(request));
    }

    @Operation(summary = "Làm mới access token")
    @PostMapping("/refresh")
    public ApiResponse<AuthResponse> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        return ApiResponse.success(authService.refreshToken(request));
    }

    @Operation(summary = "Đăng xuất")
    @PostMapping("/logout")
    public ApiResponse<Void> logout(@AuthenticationPrincipal UserPrincipal principal) {
        authService.logout(principal.getId());
        return ApiResponse.success(null, "Đăng xuất thành công");
    }
}
