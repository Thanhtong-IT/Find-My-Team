package com.findmyteam.modules.match.repository;

import com.findmyteam.modules.match.entity.Match;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface MatchRepository extends JpaRepository<Match, UUID> {

    @Query("""
        SELECT m FROM Match m
        WHERE m.userAId = :userId OR m.userBId = :userId
        ORDER BY m.createdAt DESC
        """)
    Page<Match> findByUserId(UUID userId, Pageable pageable);

    @Query("""
        SELECT m FROM Match m
        WHERE (m.userAId = :userId1 AND m.userBId = :userId2)
           OR (m.userAId = :userId2 AND m.userBId = :userId1)
        """)
    Optional<Match> findBetweenUsers(UUID userId1, UUID userId2);

    boolean existsByUserAIdAndUserBId(UUID userAId, UUID userBId);
}
