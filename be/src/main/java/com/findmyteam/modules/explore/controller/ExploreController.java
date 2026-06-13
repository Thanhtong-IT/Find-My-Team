package com.findmyteam.modules.explore.controller;

import com.findmyteam.common.dto.ApiResponse;
import com.findmyteam.modules.auth.entity.User;
import com.findmyteam.modules.explore.dto.OnlinePlayerResponse;
import com.findmyteam.modules.explore.service.ExploreService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api")
@Tag(name = "Explore", description = "APIs khám phá người chơi online")
public class ExploreController {

    private final ExploreService exploreService;

    public ExploreController(ExploreService exploreService) {
        this.exploreService = exploreService;
    }

    @Operation(summary = "Lấy danh sách người chơi online")
    @GetMapping("/players/online")
    public ApiResponse<List<OnlinePlayerResponse>> getOnlinePlayers(
            @RequestParam(required = false) UUID gameId,
            @RequestParam(defaultValue = "20") int limit) {
        return ApiResponse.success(exploreService.getOnlinePlayers(gameId, limit));
    }

    @Operation(summary = "Tìm kiếm người dùng")
    @GetMapping("/explore/search")
    public ApiResponse<List<User>> searchUsers(
            @RequestParam String q,
            @RequestParam(defaultValue = "20") int limit) {
        return ApiResponse.success(exploreService.searchUsers(q, limit));
    }
}
