package com.findmyteam.modules.invitation.service;

import com.findmyteam.common.dto.PageResponse;
import com.findmyteam.common.event.EventPublisher;
import com.findmyteam.common.event.EventType;
import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.common.exception.ResourceNotFoundException;
import com.findmyteam.modules.invitation.dto.CreateInvitationRequest;
import com.findmyteam.modules.invitation.dto.InvitationResponse;
import com.findmyteam.modules.invitation.entity.Invitation;
import com.findmyteam.modules.invitation.repository.InvitationRepository;
import com.findmyteam.modules.team.entity.Team;
import com.findmyteam.modules.team.repository.TeamMemberRepository;
import com.findmyteam.modules.team.repository.TeamRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

@Service
public class InvitationService {

    private final InvitationRepository invitationRepository;
    private final TeamRepository teamRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final EventPublisher eventPublisher;

    public InvitationService(InvitationRepository invitationRepository,
                           TeamRepository teamRepository,
                           TeamMemberRepository teamMemberRepository,
                           EventPublisher eventPublisher) {
        this.invitationRepository = invitationRepository;
        this.teamRepository = teamRepository;
        this.teamMemberRepository = teamMemberRepository;
        this.eventPublisher = eventPublisher;
    }

    public InvitationResponse createInvitation(UUID inviterId, CreateInvitationRequest request) {
        if (inviterId.equals(request.inviteeId())) {
            throw new BusinessException("Không thể tự mời chính mình");
        }

        if (request.teamId() != null) {
            Team team = teamRepository.findById(request.teamId())
                .orElseThrow(() -> new ResourceNotFoundException("Team", "id", request.teamId()));

            if (!team.getOwnerId().equals(inviterId)) {
                throw new BusinessException("Chỉ chủ nhóm mới được mời thành viên");
            }

            if (invitationRepository.existsByInviterIdAndInviteeIdAndTeamIdAndStatus(
                    inviterId, request.inviteeId(), request.teamId(), "pending")) {
                throw new BusinessException("Đã gửi lời mời trước đó");
            }
        }

        Invitation invitation = doCreateInvitation(inviterId, request);

        eventPublisher.publish(EventType.INVITATION_RECEIVED, Map.of(
            "invitationId", invitation.getId(),
            "inviteeId", request.inviteeId(),
            "inviterId", inviterId,
            "teamId", request.teamId() != null ? request.teamId() : ""
        ));

        return InvitationResponse.from(invitation);
    }

    @Transactional
    protected Invitation doCreateInvitation(UUID inviterId, CreateInvitationRequest request) {
        Invitation invitation = new Invitation();
        invitation.setInviterId(inviterId);
        invitation.setInviteeId(request.inviteeId());
        invitation.setTeamId(request.teamId());
        invitation.setType(request.teamId() != null ? "team_invite" : "play_invite");
        invitation.setMessage(request.message());
        invitation.setStatus("pending");
        return invitationRepository.save(invitation);
    }

    @Transactional(readOnly = true)
    public PageResponse<InvitationResponse> getReceivedInvitations(UUID userId, Pageable pageable) {
        Page<Invitation> invitations = invitationRepository
            .findByInviteeIdAndStatus(userId, "pending", pageable);
        return PageResponse.from(invitations.map(InvitationResponse::from));
    }

    @Transactional(readOnly = true)
    public PageResponse<InvitationResponse> getSentInvitations(UUID userId, Pageable pageable) {
        Page<Invitation> invitations = invitationRepository.findByInviterId(userId, pageable);
        return PageResponse.from(invitations.map(InvitationResponse::from));
    }

    @Transactional
    public void acceptInvitation(UUID userId, UUID invitationId) {
        Invitation invitation = invitationRepository.findById(invitationId)
            .orElseThrow(() -> new ResourceNotFoundException("Invitation", "id", invitationId));

        if (!invitation.getInviteeId().equals(userId)) {
            throw new BusinessException("Bạn không phải người được mời");
        }

        invitation.setStatus("accepted");
        invitationRepository.save(invitation);

        if ("team_invite".equals(invitation.getType()) && invitation.getTeamId() != null) {
            Team team = teamRepository.findById(invitation.getTeamId()).orElse(null);
            if (team != null && team.getStatus().equals("recruiting")) {
                // User will be added to team through a separate flow
            }
        }
    }

    @Transactional
    public void rejectInvitation(UUID userId, UUID invitationId) {
        Invitation invitation = invitationRepository.findById(invitationId)
            .orElseThrow(() -> new ResourceNotFoundException("Invitation", "id", invitationId));

        if (!invitation.getInviteeId().equals(userId)) {
            throw new BusinessException("Bạn không phải người được mời");
        }

        invitation.setStatus("rejected");
        invitationRepository.save(invitation);
    }
}
