package com.findmyteam.modules.team.controller;

import com.findmyteam.common.dto.ApiResponse;
import com.findmyteam.modules.chat.dto.SendMessageRequest;
import com.findmyteam.modules.team.dto.TeamMessageResponse;
import com.findmyteam.modules.team.service.TeamChatService;
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
@RequestMapping("/api/teams/{teamId}/messages")
@Tag(name = "Team Chat", description = "APIs gửi/nhận tin nhắn trong team")
public class TeamChatController {

    private final TeamChatService teamChatService;

    public TeamChatController(TeamChatService teamChatService) {
        this.teamChatService = teamChatService;
    }

    @Operation(summary = "Lấy lịch sử tin nhắn trong team")
    @GetMapping
    public ApiResponse<List<TeamMessageResponse>> getMessages(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID teamId,
            @PageableDefault(size = 50, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.success(
            teamChatService.getMessages(teamId, pageable).content()
        );
    }

    @Operation(summary = "Gửi tin nhắn trong team")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<TeamMessageResponse> sendMessage(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID teamId,
            @Valid @RequestBody SendMessageRequest request) {
        return ApiResponse.success(
            teamChatService.sendMessage(principal.getId(), teamId, request)
        );
    }
}
