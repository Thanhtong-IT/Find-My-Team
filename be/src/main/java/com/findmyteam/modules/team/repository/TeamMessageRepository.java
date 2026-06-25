package com.findmyteam.modules.team.repository;

import com.findmyteam.modules.team.entity.TeamMessage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface TeamMessageRepository extends JpaRepository<TeamMessage, UUID> {

    Page<TeamMessage> findByTeamIdOrderByCreatedAtDesc(UUID teamId, Pageable pageable);

    Optional<TeamMessage> findBySenderIdAndClientMessageId(UUID senderId, String clientMessageId);
}
