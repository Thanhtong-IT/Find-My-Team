package com.findmyteam.modules.community.controller;

import com.findmyteam.common.dto.ApiResponse;
import com.findmyteam.modules.community.dto.*;
import com.findmyteam.modules.community.service.CommunityService;
import com.findmyteam.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/communities")
@Tag(name = "Communities", description = "APIs quản lý community và channels")
public class CommunityController {

    private final CommunityService communityService;

    public CommunityController(CommunityService communityService) {
        this.communityService = communityService;
    }

    @Operation(summary = "Lấy danh sách communities công khai")
    @GetMapping
    public ApiResponse<List<CommunityResponse>> getCommunities(
            @RequestParam(required = false) UUID gameId,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.success(
            communityService.getPublicCommunities(gameId, pageable).content()
        );
    }

    @Operation(summary = "Tạo community mới")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<CommunityResponse> createCommunity(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreateCommunityRequest request) {
        return ApiResponse.success(
            communityService.createCommunity(principal.getId(), request)
        );
    }

    @Operation(summary = "Tham gia community")
    @PostMapping("/{communityId}/join")
    public ApiResponse<Void> joinCommunity(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID communityId) {
        communityService.joinCommunity(principal.getId(), communityId);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Rời community")
    @PostMapping("/{communityId}/leave")
    public ApiResponse<Void> leaveCommunity(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID communityId) {
        communityService.leaveCommunity(principal.getId(), communityId);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Lấy danh sách channels trong community")
    @GetMapping("/{communityId}/channels")
    public ApiResponse<List<ChannelResponse>> getChannels(@PathVariable UUID communityId) {
        return ApiResponse.success(communityService.getChannels(communityId));
    }

    @Operation(summary = "Tạo channel mới trong community")
    @PostMapping("/{communityId}/channels")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ChannelResponse> createChannel(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID communityId,
            @Valid @RequestBody CreateChannelRequest request) {
        return ApiResponse.success(
            communityService.createChannel(principal.getId(), communityId, request)
        );
    }
}
