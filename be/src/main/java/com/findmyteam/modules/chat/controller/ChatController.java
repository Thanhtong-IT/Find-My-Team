package com.findmyteam.modules.chat.controller;

import com.findmyteam.common.dto.ApiResponse;
import com.findmyteam.modules.chat.dto.MessageResponse;
import com.findmyteam.modules.chat.dto.SendMessageRequest;
import com.findmyteam.modules.chat.service.ChatService;
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
@RequestMapping("/api/communities/{communityId}/channels/{channelId}")
@Tag(name = "Chat", description = "APIs gửi/nhận tin nhắn trong channel")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @Operation(summary = "Lấy lịch sử tin nhắn trong channel")
    @GetMapping("/messages")
    public ApiResponse<java.util.List<MessageResponse>> getMessages(
            @PathVariable UUID communityId,
            @PathVariable UUID channelId,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.success(
            chatService.getMessages(communityId, channelId, pageable).content()
        );
    }

    @Operation(summary = "Gửi tin nhắn trong channel")
    @PostMapping("/messages")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<MessageResponse> sendMessage(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID communityId,
            @PathVariable UUID channelId,
            @Valid @RequestBody SendMessageRequest request) {
        return ApiResponse.success(
            chatService.sendMessage(principal.getId(), communityId, channelId, request)
        );
    }
}
