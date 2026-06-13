package com.findmyteam.modules.team.repository;

import com.findmyteam.modules.team.entity.TeamRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface TeamRequestRepository extends JpaRepository<TeamRequest, UUID> {

    Page<TeamRequest> findByUserId(UUID userId, Pageable pageable);

    Page<TeamRequest> findByStatus(String status, Pageable pageable);

    Page<TeamRequest> findByGameIdAndStatus(UUID gameId, String status, Pageable pageable);

    void deleteByUserId(UUID userId);
}
