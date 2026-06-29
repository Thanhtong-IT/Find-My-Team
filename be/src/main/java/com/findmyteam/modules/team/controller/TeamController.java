package com.findmyteam.modules.team.controller;

import com.findmyteam.common.dto.ApiResponse;
import com.findmyteam.common.dto.PageResponse;
import com.findmyteam.modules.team.dto.*;
import com.findmyteam.modules.team.service.TeamRequestService;
import com.findmyteam.modules.team.service.TeamService;
import com.findmyteam.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@Tag(name = "Teams", description = "APIs quản lý team, join request, tìm team")
public class TeamController {

    private final TeamService teamService;
    private final TeamRequestService teamRequestService;

    public TeamController(TeamService teamService, TeamRequestService teamRequestService) {
        this.teamService = teamService;
        this.teamRequestService = teamRequestService;
    }

    @Operation(summary = "Tạo team mới")
    @PostMapping("/api/teams")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<TeamDetailResponse> createTeam(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreateTeamRequest request) {
        return ApiResponse.success(teamService.createTeam(principal.getId(), request));
    }

    @Operation(summary = "Lấy team của user hiện tại")
    @GetMapping("/api/teams/my")
    public ApiResponse<TeamDetailResponse> getMyTeam(
            @AuthenticationPrincipal UserPrincipal principal) {
        return ApiResponse.success(teamService.getMyTeam(principal.getId()));
    }

    @Operation(summary = "Lấy danh sách team đang tuyển thành viên")
    @GetMapping("/api/teams/open")
    public ApiResponse<List<TeamResponse>> getOpenTeams(
            @RequestParam(required = false) UUID gameId,
            @PageableDefault(size = 10, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.success(teamService.getOpenTeams(gameId, pageable).content());
    }

    @Operation(summary = "Lấy danh sách team đang tuyển (giới hạn)")
    @GetMapping("/api/teams/recruiting")
    public ApiResponse<List<TeamResponse>> getRecruitingTeams(
            @RequestParam(defaultValue = "5") int limit) {
        return ApiResponse.success(teamService.getRecruitingTeams(limit));
    }

    @Operation(summary = "Lấy thông tin team theo ID")
    @GetMapping("/api/teams/{teamId}")
    public ApiResponse<TeamDetailResponse> getTeamById(@PathVariable UUID teamId) {
        return ApiResponse.success(teamService.getTeamById(teamId));
    }

    @Operation(summary = "Giải tán team (chỉ leader)")
    @DeleteMapping("/api/teams/{teamId}")
    public ApiResponse<Void> disbandTeam(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID teamId) {
        teamService.disbandTeam(principal.getId(), teamId);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Rời team")
    @PostMapping("/api/teams/{teamId}/leave")
    public ApiResponse<Void> leaveTeam(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID teamId) {
        teamService.leaveTeam(principal.getId(), teamId);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Kick thành viên khỏi team (chỉ leader)")
    @DeleteMapping("/api/teams/{teamId}/members/{memberId}")
    public ApiResponse<Void> kickMember(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID teamId,
            @PathVariable UUID memberId) {
        teamService.kickMember(principal.getId(), teamId, memberId);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Toggle ready status")
    @PutMapping("/api/teams/{teamId}/ready")
    public ApiResponse<Void> toggleReady(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID teamId) {
        teamService.toggleReady(principal.getId(), teamId);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Gửi yêu cầu tham gia team")
    @PostMapping("/api/teams/{teamId}/join-requests")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Void> sendJoinRequest(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID teamId,
            @RequestBody(required = false) JoinRequestBody body) {
        teamService.sendJoinRequest(principal.getId(), teamId, body);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Lấy danh sách join request của team")
    @GetMapping("/api/teams/{teamId}/join-requests")
    public ApiResponse<List<JoinRequestResponse>> getJoinRequests(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID teamId,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.success(teamService.getJoinRequests(principal.getId(), teamId, pageable).content());
    }

    @Operation(summary = "Chấp nhận join request")
    @PostMapping("/api/teams/{teamId}/join-requests/{requestId}/accept")
    public ApiResponse<Void> acceptJoinRequest(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID teamId,
            @PathVariable UUID requestId) {
        teamService.acceptJoinRequest(principal.getId(), teamId, requestId);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Từ chối join request")
    @PostMapping("/api/teams/{teamId}/join-requests/{requestId}/reject")
    public ApiResponse<Void> rejectJoinRequest(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID teamId,
            @PathVariable UUID requestId) {
        teamService.rejectJoinRequest(principal.getId(), teamId, requestId);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Tạo team request (tìm teammate)")
    @PostMapping("/api/team-requests")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<TeamRequestResponse> createTeamRequest(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreateTeamRequestDto request) {
        return ApiResponse.success(teamRequestService.createTeamRequest(principal.getId(), request));
    }

    @Operation(summary = "Lấy team requests của user")
    @GetMapping("/api/team-requests/my")
    public ApiResponse<List<TeamRequestResponse>> getMyTeamRequests(
            @AuthenticationPrincipal UserPrincipal principal,
            @PageableDefault(size = 20) Pageable pageable) {
        return ApiResponse.success(teamRequestService.getMyRequests(principal.getId(), pageable).content());
    }

    @Operation(summary = "Lấy danh sách team request đang mở")
    @GetMapping("/api/team-requests")
    public ApiResponse<List<TeamRequestResponse>> getOpenTeamRequests(
            @RequestParam(required = false) UUID gameId,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.success(teamRequestService.getOpenRequests(gameId, pageable).content());
    }

    @Operation(summary = "Đóng team request")
    @PostMapping("/api/team-requests/{requestId}/close")
    public ApiResponse<Void> closeTeamRequest(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID requestId) {
        teamRequestService.closeTeamRequest(principal.getId(), requestId);
        return ApiResponse.success(null);
    }
}
