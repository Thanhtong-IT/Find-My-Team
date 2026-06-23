package com.findmyteam.modules.user.controller;

import com.findmyteam.common.dto.ApiResponse;
import com.findmyteam.modules.auth.entity.User;
import com.findmyteam.modules.user.dto.AddGameProfileRequest;
import com.findmyteam.modules.user.dto.UpdateGameProfilesRequest;
import com.findmyteam.modules.user.dto.UpdateProfileRequest;
import com.findmyteam.modules.user.dto.UserGameProfileResponse;
import com.findmyteam.modules.user.dto.UserProfileResponse;
import com.findmyteam.modules.user.dto.VerifyRiotAccountRequest;
import com.findmyteam.modules.user.service.UserService;
import com.findmyteam.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/users")
@Tag(name = "Users", description = "APIs quản lý thông tin người dùng và game profile")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @Operation(summary = "Lấy thông tin user hiện tại")
    @GetMapping("/me")
    public ApiResponse<User> getMe(@AuthenticationPrincipal UserPrincipal principal) {
        return ApiResponse.success(userService.getCurrentUser(principal.getId()));
    }

    @Operation(summary = "Lấy profile của user hiện tại")
    @GetMapping("/me/profile")
    public ApiResponse<UserProfileResponse> getMyProfile(@AuthenticationPrincipal UserPrincipal principal) {
        return ApiResponse.success(userService.getProfile(principal.getId()));
    }

    @Operation(summary = "Cập nhật profile của user hiện tại")
    @PutMapping("/me/profile")
    public ApiResponse<UserProfileResponse> updateMyProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody UpdateProfileRequest request) {
        return ApiResponse.success(userService.updateProfile(principal.getId(), request));
    }

    @Operation(summary = "Lưu danh sách game profile của user hiện tại")
    @PutMapping("/me/game-profiles")
    public ApiResponse<UserProfileResponse> updateMyGameProfiles(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody UpdateGameProfilesRequest request) {
        return ApiResponse.success(userService.updateGameProfiles(principal.getId(), request));
    }

    @Operation(summary = "Xác minh Riot account cho game profile")
    @PostMapping("/me/game-profile/{profileId}/riot/verify")
    public ApiResponse<UserGameProfileResponse> verifyRiotAccount(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID profileId,
            @Valid @RequestBody VerifyRiotAccountRequest request) {
        return ApiResponse.success(userService.verifyRiotAccount(principal.getId(), profileId, request));
    }

    @Operation(summary = "Đồng bộ lại dữ liệu Riot cho game profile")
    @PostMapping("/me/game-profile/{profileId}/riot/refresh")
    public ApiResponse<UserGameProfileResponse> refreshRiotAccount(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID profileId) {
        return ApiResponse.success(userService.refreshRiotAccount(principal.getId(), profileId));
    }

    @Operation(summary = "Gỡ liên kết Riot account khỏi game profile")
    @DeleteMapping("/me/game-profile/{profileId}/riot")
    public ApiResponse<UserGameProfileResponse> unlinkRiotAccount(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID profileId) {
        return ApiResponse.success(userService.unlinkRiotAccount(principal.getId(), profileId));
    }

    @Operation(summary = "Thêm game profile cho user")
    @PostMapping("/me/game-profile")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<UserGameProfileResponse> addGameProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody AddGameProfileRequest request) {
        return ApiResponse.success(userService.addGameProfile(principal.getId(), request));
    }

    @Operation(summary = "Xóa game profile")
    @DeleteMapping("/me/game-profile/{profileId}")
    public ApiResponse<Void> removeGameProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID profileId) {
        userService.removeGameProfile(principal.getId(), profileId);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Lấy profile của user khác")
    @GetMapping("/{userId}/profile")
    public ApiResponse<UserProfileResponse> getUserProfile(@PathVariable UUID userId) {
        return ApiResponse.success(userService.getProfile(userId));
    }
}
