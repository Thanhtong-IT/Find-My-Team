package com.findmyteam.modules.game.repository;

import com.findmyteam.modules.game.entity.Game;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface GameRepository extends JpaRepository<Game, UUID> {

    Optional<Game> findByName(String name);

    List<Game> findByIsActiveTrue();

    List<Game> findByIsActiveTrueOrderByNameAsc();
}
