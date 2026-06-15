package com.findmyteam.modules.team.service;

import com.findmyteam.common.dto.PageResponse;
import com.findmyteam.common.event.EventPublisher;
import com.findmyteam.common.event.EventType;
import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.common.exception.ResourceNotFoundException;
import com.findmyteam.modules.game.entity.Game;
import com.findmyteam.modules.game.repository.GameRepository;
import com.findmyteam.modules.team.dto.*;
import com.findmyteam.modules.team.entity.*;
import com.findmyteam.modules.team.repository.*;
import com.findmyteam.websocket.PresenceService;
import com.findmyteam.websocket.EventSubscriber;
import com.findmyteam.modules.auth.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class TeamService {

    private final TeamRepository teamRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final JoinRequestRepository joinRequestRepository;
    private final TeamRequestRepository teamRequestRepository;
    private final GameRepository gameRepository;
    private final EventPublisher eventPublisher;
    private final PresenceService presenceService;
    private final EventSubscriber eventSubscriber;
    private final UserRepository userRepository;

    public TeamService(TeamRepository teamRepository,
                      TeamMemberRepository teamMemberRepository,
                      JoinRequestRepository joinRequestRepository,
                      TeamRequestRepository teamRequestRepository,
                      GameRepository gameRepository,
                      EventPublisher eventPublisher,
                      PresenceService presenceService,
                      EventSubscriber eventSubscriber,
                      UserRepository userRepository) {
        this.teamRepository = teamRepository;
        this.teamMemberRepository = teamMemberRepository;
        this.joinRequestRepository = joinRequestRepository;
        this.teamRequestRepository = teamRequestRepository;
        this.gameRepository = gameRepository;
        this.eventPublisher = eventPublisher;
        this.presenceService = presenceService;
        this.eventSubscriber = eventSubscriber;
        this.userRepository = userRepository;
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

        List<TeamMember> members = teamMemberRepository.findByTeamId(team.getId());
        String gameName = gameRepository.findById(team.getGameId())
            .map(Game::getName).orElse(null);

        return TeamDetailResponse.from(team, members, gameName);
    }

    @Transactional(readOnly = true)
    public TeamDetailResponse getTeamById(UUID teamId) {
        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        List<TeamMember> members = teamMemberRepository.findByTeamId(team.getId());
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

        doDisbandTeam(team);

        eventPublisher.publish(EventType.TEAM_DISBANDED, Map.of(
            "teamId", teamId,
            "ownerId", userId
        ));
    }

    @Transactional
    protected void doDisbandTeam(Team team) {
        team.setStatus("disbanded");
        teamRepository.save(team);
        teamMemberRepository.findByTeamId(team.getId())
            .forEach(member -> {
                presenceService.leaveTeamRoom(member.getUserId(), team.getId());
            });
    }

    @Transactional
    public void leaveTeam(UUID userId, UUID teamId) {
        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        if (team.getOwnerId().equals(userId)) {
            throw new BusinessException("Chủ nhóm không thể rời nhóm. Hãy giải tán hoặc chuyển quyền.");
        }

        int countBefore = teamMemberRepository.countByTeamId(teamId);

        doLeaveTeam(userId, teamId);

        if (countBefore - 1 < team.getMaxSize() && "full".equals(team.getStatus())) {
            team.setStatus("recruiting");
            teamRepository.save(team);
        }

        eventPublisher.publish(EventType.TEAM_MEMBER_LEFT, Map.of(
            "teamId", teamId,
            "userId", userId
        ));
    }

    @Transactional
    protected void doLeaveTeam(UUID userId, UUID teamId) {
        teamMemberRepository.deleteByTeamIdAndUserId(teamId, userId);
        presenceService.leaveTeamRoom(userId, teamId);
    }

    @Transactional
    public void toggleReady(UUID userId, UUID teamId) {
        Team team = teamRepository.findById(teamId)
            .orElseThrow(() -> new ResourceNotFoundException("Team", "id", teamId));

        TeamMember member = teamMemberRepository.findByTeamIdAndUserId(teamId, userId)
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

        if (teamMemberRepository.existsByTeamIdAndUserId(teamId, userId)) {
            throw new BusinessException("Bạn đã là thành viên nhóm");
        }

        if (joinRequestRepository.existsByTeamIdAndUserId(teamId, userId)) {
            throw new BusinessException("Bạn đã gửi yêu cầu trước đó");
        }

        JoinRequest request = doSendJoinRequest(userId, teamId, body != null ? body.message() : null);

        com.findmyteam.modules.auth.entity.User applicant = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
        String displayName = applicant.getDisplayName();
        if (displayName == null || displayName.isEmpty()) {
            displayName = applicant.getUsername();
        }

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

        int currentSize = teamMemberRepository.countByTeamId(team.getId());
        if (currentSize >= team.getMaxSize()) {
            throw new BusinessException("Nhóm đã đủ thành viên");
        }

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

        eventPublisher.publish(EventType.TEAM_MEMBER_JOINED, Map.of(
            "teamId", team.getId(),
            "userId", joinRequest.getUserId(),
            "displayName", displayName
        ));
        eventPublisher.publish(EventType.JOIN_REQUEST_ACCEPTED, Map.of(
            "requestId", requestId,
            "teamId", team.getId(),
            "userId", joinRequest.getUserId()
        ));

        presenceService.joinTeamRoom(joinRequest.getUserId(), team.getId());
        eventSubscriber.subscribeToTeamChannel(team.getId());
    }

    @Transactional
    protected void doAcceptJoinRequest(JoinRequest joinRequest, Team team) {
        joinRequest.setStatus("accepted");
        joinRequestRepository.save(joinRequest);

        TeamMember member = new TeamMember();
        member.setTeamId(team.getId());
        member.setUserId(joinRequest.getUserId());
        member.setRole("member");
        teamMemberRepository.save(member);

        int newCount = teamMemberRepository.countByTeamId(team.getId());
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
