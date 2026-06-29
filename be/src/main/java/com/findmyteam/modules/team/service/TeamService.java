package com.findmyteam.modules.team.service;

import com.findmyteam.common.dto.PageResponse;
import com.findmyteam.common.event.EventPublisher;
import com.findmyteam.common.event.EventType;
import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.common.exception.ResourceNotFoundException;
import com.findmyteam.modules.game.entity.Game;
import com.findmyteam.modules.game.repository.GameRepository;
import com.findmyteam.modules.notification.service.NotificationService;
import com.findmyteam.modules.team.dto.*;
import com.findmyteam.modules.team.entity.*;
import com.findmyteam.modules.team.repository.*;
import com.findmyteam.websocket.PresenceService;
import com.findmyteam.websocket.EventSubscriber;
import com.findmyteam.modules.auth.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class TeamService {

    private static final Logger log = LoggerFactory.getLogger(TeamService.class);

    private final TeamRepository teamRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final JoinRequestRepository joinRequestRepository;
    private final TeamRequestRepository teamRequestRepository;
    private final GameRepository gameRepository;
    private final EventPublisher eventPublisher;
    private final PresenceService presenceService;
    private final EventSubscriber eventSubscriber;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public TeamService(TeamRepository teamRepository,
                      TeamMemberRepository teamMemberRepository,
                      JoinRequestRepository joinRequestRepository,
                      TeamRequestRepository teamRequestRepository,
                      GameRepository gameRepository,
                      EventPublisher eventPublisher,
                      PresenceService presenceService,
                      EventSubscriber eventSubscriber,
                      UserRepository userRepository,
                      NotificationService notificationService) {
        this.teamRepository = teamRepository;
        this.teamMemberRepository = teamMemberRepository;
        this.joinRequestRepository = joinRequestRepository;
        this.teamRequestRepository = teamRequestRepository;
        this.gameRepository = gameRepository;
        this.eventPublisher = eventPublisher;
        this.presenceService = presenceService;
        this.eventSubscriber = eventSubscriber;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public PageResponse<TeamResponse> getOpenTeams(UUID gameId, Pageable pageable) {
        Page<Team> teams;
        if (gameId != null) {
            teams = teamRepository.findByStatusAndGameId("recruiting", gameId, pageable);
        } else {
            teams = teamRepository.findByStatus("recruiting", pageable);
        }

        Page<TeamResponse> responsePage = teams.map(team -> {
            int memberCount = teamMemberRepository.countByTeamId(team.getId());
            String gameName = gameRepository.findById(team.getGameId())
                .map(Game::getName).orElse(null);
            return TeamResponse.from(team, memberCount, gameName);
        });

        return PageResponse.from(responsePage);
    }

    @Transactional(readOnly = true)
    public List<TeamResponse> getRecruitingTeams(int limit) {
        return teamRepository.findByStatus("recruiting",
                org.springframework.data.domain.PageRequest.of(0, limit)).stream()
            .map(team -> {
                int memberCount = teamMemberRepository.countByTeamId(team.getId());
                String gameName = gameRepository.findById(team.getGameId())
                    .map(Game::getName).orElse(null);
                return TeamResponse.from(team, memberCount, gameName);
            })
            .toList();
    }

    @Transactional(readOnly = true)
    public TeamDetailResponse getMyTeam(UUID userId) {
        Team team = teamRepository.findActiveTeamByUserId(userId)
            .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa có nhóm nào"));

        List<TeamMember> members = teamMemberRepository.findActiveMembersByTeamId(team.getId());
        String gameName = gameRepository.findById(team.getGameId())
            .map(Game::getName).orElse(null);

        return TeamDetailResponse.from(team, members, gameName);
    }

    @Transactional(readOnly = true)
    public TeamDetailResponse getTeamById(UUID teamId) {
        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        List<TeamMember> members = teamMemberRepository.findActiveMembersByTeamId(team.getId());
        String gameName = gameRepository.findById(team.getGameId())
            .map(Game::getName).orElse(null);

        return TeamDetailResponse.from(team, members, gameName);
    }

    @Transactional
    public TeamDetailResponse createTeam(UUID userId, CreateTeamRequest request) {
        teamRepository.findActiveTeamByUserId(userId).ifPresent(t -> {
            throw new BusinessException("Bạn đã có nhóm. Hãy rời nhóm trước.");
        });

        Game game = gameRepository.findById(request.gameId())
            .orElseThrow(() -> new ResourceNotFoundException("Game", "id", request.gameId()));

        Team team = doCreateTeam(userId, request);

        presenceService.joinTeamRoom(userId, team.getId());
        eventSubscriber.subscribeToTeamChannel(team.getId());

        eventPublisher.publish(EventType.TEAM_CREATED, Map.of(
            "teamId", team.getId(),
            "ownerId", userId,
            "gameId", request.gameId()
        ));

        List<TeamMember> members = teamMemberRepository.findByTeamId(team.getId());
        return TeamDetailResponse.from(team, members, game.getName());
    }

    @Transactional
    protected Team doCreateTeam(UUID userId, CreateTeamRequest request) {
        Team team = new Team();
        team.setGameId(request.gameId());
        team.setName(request.name());
        team.setRequiredRank(request.requiredRank());
        team.setMaxSize(request.maxSize() > 0 ? request.maxSize() : 5);
        team.setDescription(request.description());
        team.setRequiredRoles(request.requiredRoles());
        team.setRequireMic(request.requireMic());
        team.setOwnerId(userId);
        team.setStatus("recruiting");
        team = teamRepository.save(team);

        TeamMember owner = new TeamMember();
        owner.setTeamId(team.getId());
        owner.setUserId(userId);
        owner.setRole("owner");
        owner.setReady(true);
        teamMemberRepository.save(owner);

        return team;
    }

    @Transactional
    public void disbandTeam(UUID userId, UUID teamId) {
        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        if (!team.getOwnerId().equals(userId)) {
            throw new BusinessException("Chỉ chủ nhóm mới có thể giải tán nhóm");
        }

        // IMPORTANT: Get only ACTIVE members BEFORE any changes
        // This ensures we only notify active members, not those who left
        List<TeamMember> activeMembers = teamMemberRepository.findActiveMembersByTeamId(teamId);
        String teamName = team.getName();

        // Disband the team
        doDisbandTeam(team);

        // Notify all ACTIVE members (except the leader who initiated the disband)
        for (TeamMember member : activeMembers) {
            // Skip the leader - they already know they disbanded the team
            if (member.getUserId().equals(userId)) {
                continue;
            }
            notificationService.createNotification(
                    member.getUserId(),
                    "system",
                    "Nhóm đã bị giải tán",
                    "Nhóm " + teamName + " đã bị giải tán bởi chủ nhóm",
                    teamId.toString(),
                    null
            );
        }

        eventPublisher.publish(EventType.TEAM_DISBANDED, Map.of(
            "teamId", teamId,
            "ownerId", userId
        ));
    }

    @Transactional
    protected void doDisbandTeam(Team team) {
        // Update ALL team members' status to LEFT before deleting the team
        List<TeamMember> allMembers = teamMemberRepository.findByTeamId(team.getId());
        for (TeamMember member : allMembers) {
            member.setStatus(TeamMember.STATUS_LEFT);
            member.setLeftAt(OffsetDateTime.now());
            teamMemberRepository.save(member);
            presenceService.leaveTeamRoom(member.getUserId(), team.getId());
        }

        // Soft delete: update team status to disbanded
        team.setStatus("disbanded");
        teamRepository.save(team);
    }

    @Transactional
    public void leaveTeam(UUID userId, UUID teamId) {
        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        if (team.getOwnerId().equals(userId)) {
            throw new BusinessException("Chủ nhóm không thể rời nhóm. Hãy giải tán hoặc chuyển quyền.");
        }

        // Get remaining members BEFORE the user leaves
        List<UUID> remainingMemberIds = teamMemberRepository.findActiveMembersByTeamId(teamId).stream()
                .filter(m -> !m.getUserId().equals(userId))
                .map(TeamMember::getUserId)
                .collect(Collectors.toList());
        int countBefore = remainingMemberIds.size() + 1; // +1 for the user who is leaving

        doLeaveTeam(userId, teamId);

        if (countBefore - 1 < team.getMaxSize() && "full".equals(team.getStatus())) {
            team.setStatus("recruiting");
            teamRepository.save(team);
        }

        log.info("=== LEAVE TEAM === Publishing TEAM_MEMBER_LEFT to events:team:{}", teamId);
        log.info("LEAVE: Remaining member count: {}, memberIds: {}", remainingMemberIds.size(), remainingMemberIds);

        // Broadcast to team room so remaining members update their member list
        eventPublisher.publish(EventType.TEAM_MEMBER_LEFT, Map.of(
                "teamId", teamId,
                "leftUserId", userId,
                "remainingMembers", remainingMemberIds
        ));
    }

    @Transactional
    public void kickMember(UUID ownerId, UUID teamId, UUID memberId) {
        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        if (!team.getOwnerId().equals(ownerId)) {
            throw new BusinessException("Chỉ chủ nhóm mới có thể kick thành viên");
        }

        if (team.getOwnerId().equals(memberId)) {
            throw new BusinessException("Không thể kick chủ nhóm");
        }

        TeamMember member = teamMemberRepository.findActiveMemberByTeamIdAndUserId(teamId, memberId)
            .orElseThrow(() -> new BusinessException("Thành viên không tồn tại trong nhóm"));

        // IMPORTANT: Get all member IDs BEFORE making changes
        // This includes the owner who is still active
        List<UUID> allMemberIds = teamMemberRepository.findActiveMembersByTeamId(teamId).stream()
                .map(TeamMember::getUserId)
                .collect(Collectors.toList());
        log.info("KICK: Will notify {} members including owner", allMemberIds.size());

        int countBefore = allMemberIds.size();

        // Update member status to LEFT
        member.setStatus(TeamMember.STATUS_LEFT);
        member.setLeftAt(OffsetDateTime.now());
        teamMemberRepository.save(member);
        presenceService.leaveTeamRoom(memberId, teamId);

        log.info("KICK: Successfully updated member status to LEFT, memberId={}", memberId);

        if (countBefore - 1 < team.getMaxSize() && "full".equals(team.getStatus())) {
            team.setStatus("recruiting");
            teamRepository.save(team);
        }

        // Broadcast to team room - ALL remaining members (including owner) get the update
        log.info("KICK: Publishing TEAM_MEMBER_LEFT to events:team:{}", teamId);
        eventPublisher.publish(EventType.TEAM_MEMBER_LEFT, Map.of(
                "teamId", teamId,
                "kickedUserId", memberId,
                "kickedBy", ownerId,
                "isKick", true
        ));

        // Send TEAM_MEMBER_KICKED to the kicked user so they exit the team screen
        log.info("KICK: Publishing TEAM_MEMBER_KICKED to events:user:{}", memberId);
        eventPublisher.publish(EventType.TEAM_MEMBER_KICKED, Map.of(
                "teamId", teamId,
                "userId", memberId,
                "kickedBy", ownerId
        ));
    }

    @Transactional
    protected void doLeaveTeam(UUID userId, UUID teamId) {
        log.info("doLeaveTeam: userId={}, teamId={}", userId, teamId);
        
        // Check for ACTIVE member first
        TeamMember member = teamMemberRepository.findActiveMemberByTeamIdAndUserId(teamId, userId)
            .orElse(null);
            
        if (member == null) {
            // Check if there's any record (even LEFT status)
            Optional<TeamMember> anyRecord = teamMemberRepository.findByTeamIdAndUserId(teamId, userId);
            if (anyRecord.isPresent()) {
                log.warn("doLeaveTeam: found record but status is not ACTIVE, status={}", anyRecord.get().getStatus());
                // Reactivate and then set to LEFT
                member = anyRecord.get();
                member.setStatus(TeamMember.STATUS_LEFT);
                member.setLeftAt(OffsetDateTime.now());
                teamMemberRepository.save(member);
                presenceService.leaveTeamRoom(userId, teamId);
                return;
            }
            throw new BusinessException("Bạn không phải thành viên nhóm");
        }
        
        log.info("doLeaveTeam: found active member, setting status to LEFT");
        member.setStatus(TeamMember.STATUS_LEFT);
        member.setLeftAt(OffsetDateTime.now());
        teamMemberRepository.save(member);
        presenceService.leaveTeamRoom(userId, teamId);
    }

    @Transactional
    public void toggleReady(UUID userId, UUID teamId) {
        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        TeamMember member = teamMemberRepository.findActiveMemberByTeamIdAndUserId(teamId, userId)
            .orElseThrow(() -> new BusinessException("Bạn không phải thành viên nhóm"));

        boolean newReady = !member.isReady();
        doToggleReady(member, newReady);

        eventPublisher.publish(EventType.TEAM_MEMBER_READY, Map.of(
            "teamId", teamId,
            "userId", userId,
            "isReady", newReady
        ));
    }

    @Transactional
    protected void doToggleReady(TeamMember member, boolean isReady) {
        member.setReady(isReady);
        teamMemberRepository.save(member);
    }

    @Transactional
    public void sendJoinRequest(UUID userId, UUID teamId, JoinRequestBody body) {
        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        if (!team.getStatus().equals("recruiting")) {
            throw new BusinessException("Nhóm này không còn tuyển thành viên");
        }

        // Check user đang là ACTIVE thành viên của team này
        if (teamMemberRepository.findActiveMemberByTeamIdAndUserId(teamId, userId).isPresent()) {
            throw new BusinessException("Bạn đã là thành viên nhóm");
        }

        // Check user đang ở team khác (không được xin team mới)
        Optional<Team> currentTeam = teamRepository.findActiveTeamByUserId(userId);
        if (currentTeam.isPresent()) {
            throw new BusinessException("Bạn đang ở trong một đội khác");
        }

        // Check có PENDING request không → chặn
        if (joinRequestRepository.existsByTeamIdAndUserIdAndStatus(teamId, userId, "pending")) {
            throw new BusinessException("Bạn đã gửi yêu cầu trước đó");
        }

        // Tìm request cũ (ACCEPTED/REJECTED/CANCELLED) → reuse
        Optional<JoinRequest> existingRequest = joinRequestRepository.findByTeamIdAndUserId(teamId, userId);
        JoinRequest request;

        if (existingRequest.isPresent()) {
            // Reuse row cũ, chỉ update status và message
            request = existingRequest.get();
            request.setStatus("pending");
            request.setMessage(body != null ? body.message() : null);
            request = joinRequestRepository.save(request);
        } else {
            // Tạo request mới
            request = doSendJoinRequest(userId, teamId, body != null ? body.message() : null);
        }

        com.findmyteam.modules.auth.entity.User applicant = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
        String displayName = applicant.getDisplayName();
        if (displayName == null || displayName.isEmpty()) {
            displayName = applicant.getUsername();
        }

        // Create notification for team owner
        String teamName = team.getName();
        notificationService.createNotification(
                team.getOwnerId(),
                "join_request",
                "Yêu cầu tham gia nhóm",
                displayName + " muốn tham gia " + teamName,
                teamId.toString(),
                userId.toString()
        );

        eventPublisher.publish(EventType.JOIN_REQUEST_CREATED, Map.of(
            "requestId", request.getId(),
            "teamId", teamId,
            "userId", userId,
            "ownerId", team.getOwnerId(),
            "displayName", displayName
        ));
    }

    @Transactional
    protected JoinRequest doSendJoinRequest(UUID userId, UUID teamId, String message) {
        JoinRequest request = new JoinRequest();
        request.setTeamId(teamId);
        request.setUserId(userId);
        request.setMessage(message);
        request.setStatus("pending");
        return joinRequestRepository.save(request);
    }

    @Transactional(readOnly = true)
    public PageResponse<JoinRequestResponse> getJoinRequests(UUID ownerId, UUID teamId, Pageable pageable) {
        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        if (!team.getOwnerId().equals(ownerId)) {
            throw new BusinessException("Chỉ chủ nhóm mới có thể xem yêu cầu");
        }

        Page<JoinRequest> requests = joinRequestRepository
            .findByTeamIdAndStatus(teamId, "pending", pageable);

        return PageResponse.from(requests.map(JoinRequestResponse::from));
    }

    @Transactional
    public void acceptJoinRequest(UUID ownerId, UUID teamId, UUID requestId) {
        JoinRequest joinRequest = joinRequestRepository.findById(requestId)
            .orElseThrow(() -> new ResourceNotFoundException("Join request", "id", requestId));

        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        if (!team.getOwnerId().equals(ownerId)) {
            throw new BusinessException("Chỉ chủ nhóm mới có thể chấp nhận yêu cầu");
        }

        int currentSize = teamMemberRepository.countActiveMembersByTeamId(team.getId());
        if (currentSize >= team.getMaxSize()) {
            throw new BusinessException("Nhóm đã đủ thành viên");
        }

        UUID requesterId = joinRequest.getUserId();
        log.info("=== ACCEPT JOIN REQUEST === requesterId={}, teamId={}", requesterId, teamId);

        doAcceptJoinRequest(joinRequest, team);

        String displayName = "Thành viên mới";
        if (joinRequest.getUser() != null) {
            displayName = joinRequest.getUser().getDisplayName();
            if (displayName == null || displayName.isEmpty()) {
                displayName = joinRequest.getUser().getUsername();
            }
        }
        if (displayName == null || displayName.isEmpty()) {
            displayName = "Thành viên mới";
        }

        // Publish TEAM_MEMBER_JOINED đến team channel
        log.info("Publishing TEAM_MEMBER_JOINED to events:team:{}", team.getId());
        eventPublisher.publish(EventType.TEAM_MEMBER_JOINED, Map.of(
            "teamId", team.getId(),
            "userId", requesterId,
            "displayName", displayName
        ));

        // Publish JOIN_REQUEST_ACCEPTED đến user channel
        log.info("Publishing JOIN_REQUEST_ACCEPTED to events:user:{}", requesterId);

        // Create notification for requester
        notificationService.createNotification(
                requesterId,
                "request_accepted",
                "Yêu cầu được chấp nhận!",
                "Bạn đã được thêm vào nhóm " + team.getName(),
                teamId.toString(),
                null
        );

        eventPublisher.publish(EventType.JOIN_REQUEST_ACCEPTED, Map.of(
            "requestId", requestId,
            "teamId", team.getId(),
            "userId", requesterId
        ));

        presenceService.joinTeamRoom(requesterId, team.getId());
        eventSubscriber.subscribeToTeamChannel(team.getId());
    }

    @Transactional
    protected void doAcceptJoinRequest(JoinRequest joinRequest, Team team) {
        joinRequest.setStatus("accepted");
        joinRequestRepository.save(joinRequest);

        Optional<TeamMember> existingMember = teamMemberRepository.findByTeamIdAndUserId(team.getId(), joinRequest.getUserId());
        TeamMember member;
        if (existingMember.isPresent()) {
            member = existingMember.get();
            member.setStatus(TeamMember.STATUS_ACTIVE);
            member.setLeftAt(null);
            member.setReady(false);
        } else {
            member = new TeamMember();
            member.setTeamId(team.getId());
            member.setUserId(joinRequest.getUserId());
            member.setStatus(TeamMember.STATUS_ACTIVE);
            member.setReady(false);
        }
        member.setRole("member");
        teamMemberRepository.save(member);

        int newCount = teamMemberRepository.countActiveMembersByTeamId(team.getId());
        if (newCount >= team.getMaxSize()) {
            team.setStatus("full");
            teamRepository.save(team);
        }
    }

    @Transactional
    public void rejectJoinRequest(UUID ownerId, UUID teamId, UUID requestId) {
        JoinRequest joinRequest = joinRequestRepository.findById(requestId)
            .orElseThrow(() -> new ResourceNotFoundException("Join request", "id", requestId));

        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        if (!team.getOwnerId().equals(ownerId)) {
            throw new BusinessException("Chỉ chủ nhóm mới có thể từ chối yêu cầu");
        }

        doRejectJoinRequest(joinRequest);

        // Create notification for requester
        notificationService.createNotification(
                joinRequest.getUserId(),
                "request_rejected",
                "Yêu cầu bị từ chối",
                "Yêu cầu tham gia " + team.getName() + " của bạn đã bị từ chối",
                teamId.toString(),
                null
        );

        eventPublisher.publish(EventType.JOIN_REQUEST_REJECTED, Map.of(
            "requestId", requestId,
            "teamId", team.getId(),
            "userId", joinRequest.getUserId()
        ));
    }

    @Transactional
    protected void doRejectJoinRequest(JoinRequest joinRequest) {
        joinRequest.setStatus("rejected");
        joinRequestRepository.save(joinRequest);
    }
}
