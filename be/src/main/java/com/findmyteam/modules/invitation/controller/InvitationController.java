package com.findmyteam.modules.invitation.controller;

import com.findmyteam.common.dto.ApiResponse;
import com.findmyteam.modules.invitation.dto.CreateInvitationRequest;
import com.findmyteam.modules.invitation.dto.InvitationResponse;
import com.findmyteam.modules.invitation.service.InvitationService;
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

import java.util.UUID;

@RestController
@RequestMapping("/api/invitations")
@Tag(name = "Invitations", description = "APIs mời người chơi vào team")
public class InvitationController {

    private final InvitationService invitationService;

    public InvitationController(InvitationService invitationService) {
        this.invitationService = invitationService;
    }

    @Operation(summary = "Tạo lời mời tham gia team")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<InvitationResponse> createInvitation(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreateInvitationRequest request) {
        return ApiResponse.success(
            invitationService.createInvitation(principal.getId(), request)
        );
    }

    @Operation(summary = "Lấy danh sách lời mời đã nhận")
    @GetMapping("/received")
    public ApiResponse<java.util.List<InvitationResponse>> getReceivedInvitations(
            @AuthenticationPrincipal UserPrincipal principal,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.success(
            invitationService.getReceivedInvitations(principal.getId(), pageable).content()
        );
    }

    @Operation(summary = "Lấy danh sách lời mời đã gửi")
    @GetMapping("/sent")
    public ApiResponse<java.util.List<InvitationResponse>> getSentInvitations(
            @AuthenticationPrincipal UserPrincipal principal,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.success(
            invitationService.getSentInvitations(principal.getId(), pageable).content()
        );
    }

    @Operation(summary = "Chấp nhận lời mời")
    @PostMapping("/{invitationId}/accept")
    public ApiResponse<Void> acceptInvitation(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID invitationId) {
        invitationService.acceptInvitation(principal.getId(), invitationId);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Từ chối lời mời")
    @PostMapping("/{invitationId}/reject")
    public ApiResponse<Void> rejectInvitation(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID invitationId) {
        invitationService.rejectInvitation(principal.getId(), invitationId);
        return ApiResponse.success(null);
    }
}
