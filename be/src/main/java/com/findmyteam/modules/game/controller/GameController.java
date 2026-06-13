package com.findmyteam.modules.game.controller;

import com.findmyteam.common.dto.ApiResponse;
import com.findmyteam.modules.game.dto.GameResponse;
import com.findmyteam.modules.game.service.GameService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/games")
@Tag(name = "Games", description = "APIs thông tin game")
public class GameController {

    private final GameService gameService;

    public GameController(GameService gameService) {
        this.gameService = gameService;
    }

    @Operation(summary = "Lấy danh sách tất cả games")
    @GetMapping
    public ApiResponse<List<GameResponse>> getAllGames() {
        return ApiResponse.success(gameService.getAllGames());
    }

    @Operation(summary = "Lấy danh sách games phổ biến")
    @GetMapping("/popular")
    public ApiResponse<List<GameResponse>> getPopularGames() {
        return ApiResponse.success(gameService.getPopularGames());
    }

    @Operation(summary = "Lấy thông tin game theo ID")
    @GetMapping("/{id}")
    public ApiResponse<GameResponse> getGameById(@PathVariable UUID id) {
        return ApiResponse.success(gameService.getGameById(id));
    }
}
