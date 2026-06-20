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
import com.findmyteam.modules.notification.service.NotificationService;
import com.findmyteam.modules.team.entity.Team;
import com.findmyteam.modules.team.entity.TeamMember;
import com.findmyteam.modules.team.repository.TeamMemberRepository;
import com.findmyteam.modules.team.repository.TeamRepository;
import com.findmyteam.modules.auth.repository.UserRepository;
import com.findmyteam.websocket.EventSubscriber;
import com.findmyteam.websocket.PresenceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class InvitationService {

    private static final Logger log = LoggerFactory.getLogger(InvitationService.class);

    private final InvitationRepository invitationRepository;
    private final TeamRepository teamRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final UserRepository userRepository;
    private final EventPublisher eventPublisher;
    private final NotificationService notificationService;
    private final PresenceService presenceService;
    private final EventSubscriber eventSubscriber;

    public InvitationService(InvitationRepository invitationRepository,
                           TeamRepository teamRepository,
                           TeamMemberRepository teamMemberRepository,
                           UserRepository userRepository,
                           EventPublisher eventPublisher,
                           NotificationService notificationService,
                           PresenceService presenceService,
                           EventSubscriber eventSubscriber) {
        this.invitationRepository = invitationRepository;
        this.teamRepository = teamRepository;
        this.teamMemberRepository = teamMemberRepository;
        this.userRepository = userRepository;
        this.eventPublisher = eventPublisher;
        this.notificationService = notificationService;
        this.presenceService = presenceService;
        this.eventSubscriber = eventSubscriber;
    }

    @Transactional
    public InvitationResponse createInvitation(UUID inviterId, CreateInvitationRequest request) {
        log.info("=== CREATE INVITATION === inviterId={}, inviteeId={}, teamId={}", inviterId, request.inviteeId(), request.teamId());

        if (inviterId.equals(request.inviteeId())) {
            log.warn("createInvitation FAILED: self-invitation attempt inviterId={}", inviterId);
            throw new BusinessException("Không thể tự mời chính mình");
        }

        String inviterName = userRepository.findById(inviterId)
                .map(u -> u.getDisplayName() != null ? u.getDisplayName() : u.getUsername())
                .orElse("Người dùng");

        String teamName = null;
        if (request.teamId() != null) {
            log.info("createInvitation: checking team teamId={}", request.teamId());
            Team team = teamRepository.findById(request.teamId())
                .orElseThrow(() -> {
                    log.warn("createInvitation FAILED: team not found teamId={}", request.teamId());
                    return new ResourceNotFoundException("Team", "id", request.teamId());
                });

            log.info("createInvitation: team found name={}, ownerId={}, inviterId={}", team.getName(), team.getOwnerId(), inviterId);

            if (!team.getOwnerId().equals(inviterId)) {
                log.warn("createInvitation FAILED: not team owner teamOwnerId={}, inviterId={}", team.getOwnerId(), inviterId);
                throw new BusinessException("Chỉ chủ nhóm mới được mời thành viên");
            }

            teamName = team.getName();

            if (invitationRepository.existsByInviterIdAndInviteeIdAndTeamIdAndStatus(
                    inviterId, request.inviteeId(), request.teamId(), "pending")) {
                log.warn("createInvitation FAILED: duplicate invitation exists inviterId={}, inviteeId={}, teamId={}", inviterId, request.inviteeId(), request.teamId());
                throw new BusinessException("Đã gửi lời mời trước đó");
            }

            log.info("createInvitation: all checks passed, creating invitation");
        } else {
            log.info("createInvitation: play_invite (no teamId), checking duplicate");
            if (invitationRepository.existsByInviterIdAndInviteeIdAndTeamIdAndStatus(
                    inviterId, request.inviteeId(), null, "pending")) {
                log.warn("createInvitation FAILED: duplicate play_invite exists inviterId={}, inviteeId={}", inviterId, request.inviteeId());
                throw new BusinessException("Đã gửi lời mời trước đó");
            }
        }

        Invitation invitation = doCreateInvitation(inviterId, request);
        log.info("createInvitation SUCCESS: invitationId={}", invitation.getId());

        // Create notification for invitee
        String title = "Bạn có lời mời mới";
        String body;
        if (teamName != null) {
            body = inviterName + " đã mời bạn tham gia nhóm " + teamName;
        } else {
            body = inviterName + " muốn chơi cùng bạn";
        }
        notificationService.createNotification(
                request.inviteeId(),
                "team_invite",
                title,
                body,
                invitation.getId().toString(),
                inviterId.toString()
        );

        // Publish WebSocket event
        eventPublisher.publish(EventType.INVITATION_RECEIVED, Map.of(
            "invitationId", invitation.getId(),
            "userId", request.inviteeId(),
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

        // Prevent re-processing accepted invitations
        if (!"pending".equals(invitation.getStatus())) {
            throw new BusinessException("Lời mời đã được xử lý trước đó");
        }

        invitation.setStatus("accepted");
        Invitation updatedInvitation = invitationRepository.save(invitation);
        log.info("acceptInvitation: invitation saved id={}, status={}", updatedInvitation.getId(), updatedInvitation.getStatus());

        if ("team_invite".equals(invitation.getType()) && invitation.getTeamId() != null) {
            Team team = teamRepository.findById(invitation.getTeamId())
                .orElseThrow(() -> new ResourceNotFoundException("Team", "id", invitation.getTeamId()));

            // Check if team is still recruiting
            if (!"recruiting".equals(team.getStatus())) {
                throw new BusinessException("Nhóm không còn tuyển thành viên");
            }

            // Check if team is full
            int currentSize = teamMemberRepository.countActiveMembersByTeamId(team.getId());
            if (currentSize >= team.getMaxSize()) {
                throw new BusinessException("Nhóm đã đủ thành viên");
            }

            // Check if user is already an ACTIVE member
            Optional<TeamMember> existingMember = teamMemberRepository.findActiveMemberByTeamIdAndUserId(team.getId(), userId);
            if (existingMember.isPresent()) {
                throw new BusinessException("Bạn đã là thành viên của nhóm");
            }

            // Check if user has a LEFT record - reactivate it instead of creating new
            Optional<TeamMember> leftMember = teamMemberRepository.findByTeamIdAndUserId(team.getId(), userId);
            TeamMember member;
            if (leftMember.isPresent()) {
                // Reactivate existing LEFT record
                member = leftMember.get();
                member.setStatus(TeamMember.STATUS_ACTIVE);
                member.setRole("member");
                member.setReady(false);
                member.setLeftAt(null);
                member = teamMemberRepository.save(member);
                log.info("acceptInvitation: TeamMember reactivated id={}, teamId={}, userId={}", 
                    member.getId(), member.getTeamId(), member.getUserId());
            } else {
                // Create new TeamMember
                member = new TeamMember();
                member.setTeamId(team.getId());
                member.setUserId(userId);
                member.setRole("member");
                member.setStatus(TeamMember.STATUS_ACTIVE);
                member.setReady(false);
                member = teamMemberRepository.save(member);
                log.info("acceptInvitation: TeamMember created id={}, teamId={}, userId={}",
                    member.getId(), member.getTeamId(), member.getUserId());
            }

            int newCount = teamMemberRepository.countActiveMembersByTeamId(team.getId());
            if (newCount >= team.getMaxSize()) {
                team.setStatus("full");
                teamRepository.save(team);
            }

            presenceService.joinTeamRoom(userId, team.getId());
            eventSubscriber.subscribeToTeamChannel(team.getId());

            // Get inviter display name for event
            String inviterName = "Người dùng";
            var inviter = userRepository.findById(invitation.getInviterId()).orElse(null);
            if (inviter != null) {
                inviterName = inviter.getDisplayName() != null ? inviter.getDisplayName() : inviter.getUsername();
            }

            // Publish TEAM_MEMBER_JOINED to team channel
            eventPublisher.publish(EventType.TEAM_MEMBER_JOINED, Map.of(
                "teamId", team.getId(),
                "userId", userId,
                "displayName", inviterName
            ));
            log.info("acceptInvitation: TEAM_MEMBER_JOINED event published teamId={}, userId={}", team.getId(), userId);
            // Note: member_joined notification removed - notifications table constraint only allows specific types
        }
        log.info("acceptInvitation: SUCCESS userId={}, invitationId={}", userId, invitationId);
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
