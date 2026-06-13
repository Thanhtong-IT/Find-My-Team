package com.findmyteam.modules.game.service;

import com.findmyteam.common.exception.ResourceNotFoundException;
import com.findmyteam.modules.game.dto.GameResponse;
import com.findmyteam.modules.game.entity.Game;
import com.findmyteam.modules.game.repository.GameRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class GameService {

    private final GameRepository gameRepository;

    public GameService(GameRepository gameRepository) {
        this.gameRepository = gameRepository;
    }

    @Transactional(readOnly = true)
    public List<GameResponse> getAllGames() {
        return gameRepository.findByIsActiveTrueOrderByNameAsc().stream()
            .map(GameResponse::from)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<GameResponse> getPopularGames() {
        return gameRepository.findByIsActiveTrue().stream()
            .map(game -> GameResponse.from(game))
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public GameResponse getGameById(UUID id) {
        Game game = gameRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Game", "id", id));
        return GameResponse.from(game);
    }

    @Transactional(readOnly = true)
    public Game getEntityById(UUID id) {
        return gameRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Game", "id", id));
    }
}
