package com.findmyteam.modules.match.controller;

import com.findmyteam.common.dto.ApiResponse;
import com.findmyteam.modules.match.dto.CreateSwipeRequest;
import com.findmyteam.modules.match.dto.MatchResponse;
import com.findmyteam.modules.match.service.MatchService;
import com.findmyteam.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@Tag(name = "Match", description = "APIs swipe và match người chơi")
public class MatchController {

    private final MatchService matchService;

    public MatchController(MatchService matchService) {
        this.matchService = matchService;
    }

    @Operation(summary = "Swipe một người chơi (like/dislike)")
    @PostMapping("/swipes")
    public ApiResponse<Void> createSwipe(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreateSwipeRequest request) {
        matchService.createSwipe(principal.getId(), request);
        return ApiResponse.success(null);
    }

    @Operation(summary = "Lấy danh sách match của user")
    @GetMapping("/matches")
    public ApiResponse<java.util.List<MatchResponse>> getMatches(
            @AuthenticationPrincipal UserPrincipal principal,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.success(
            matchService.getMatches(principal.getId(), pageable).content()
        );
    }
}
