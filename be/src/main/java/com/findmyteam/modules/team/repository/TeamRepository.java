package com.findmyteam.modules.team.repository;

import com.findmyteam.modules.team.entity.Team;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TeamRepository extends JpaRepository<Team, UUID> {

    Page<Team> findByStatus(String status, Pageable pageable);

    Page<Team> findByStatusAndGameId(String status, UUID gameId, Pageable pageable);

    @Query("""
        SELECT t FROM Team t
        JOIN TeamMember tm ON tm.teamId = t.id
        WHERE tm.userId = :userId AND t.status != 'disbanded'
        """)
    Optional<Team> findActiveTeamByUserId(UUID userId);

    @Query("""
        SELECT t FROM Team t
        JOIN TeamMember tm ON tm.teamId = t.id
        WHERE tm.userId = :userId AND t.status = 'recruiting'
        """)
    Optional<Team> findRecruitingTeamByUserId(UUID userId);

    List<Team> findByOwnerId(UUID ownerId);

    @Query("""
        SELECT t FROM Team t
        WHERE t.status = 'recruiting' AND t.gameId = :gameId
        ORDER BY t.createdAt DESC
        """)
    Page<Team> findOpenTeamsByGame(UUID gameId, Pageable pageable);

    @Query("""
        SELECT t FROM Team t
        WHERE t.status = 'recruiting'
        ORDER BY t.createdAt DESC
        """)
    Page<Team> findOpenTeams(Pageable pageable);
}
