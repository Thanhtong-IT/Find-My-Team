package com.findmyteam.modules.invitation.repository;

import com.findmyteam.modules.invitation.entity.Invitation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface InvitationRepository extends JpaRepository<Invitation, UUID> {

    Page<Invitation> findByInviteeIdAndStatus(UUID inviteeId, String status, Pageable pageable);

    Page<Invitation> findByInviterId(UUID inviterId, Pageable pageable);

    boolean existsByInviterIdAndInviteeIdAndTeamIdAndStatus(UUID inviterId, UUID inviteeId, UUID teamId, String status);
}
