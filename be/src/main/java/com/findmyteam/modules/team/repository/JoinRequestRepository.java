package com.findmyteam.modules.team.repository;

import com.findmyteam.modules.team.entity.JoinRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface JoinRequestRepository extends JpaRepository<JoinRequest, UUID> {

    Page<JoinRequest> findByTeamIdAndStatus(UUID teamId, String status, Pageable pageable);

    Optional<JoinRequest> findByTeamIdAndUserId(UUID teamId, UUID userId);

    boolean existsByTeamIdAndUserId(UUID teamId, UUID userId);

    void deleteByTeamIdAndUserId(UUID teamId, UUID userId);
}
