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
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class TeamRequestService {

    private final TeamRequestRepository teamRequestRepository;
    private final GameRepository gameRepository;
    private final EventPublisher eventPublisher;

    public TeamRequestService(TeamRequestRepository teamRequestRepository,
                            GameRepository gameRepository,
                            EventPublisher eventPublisher) {
        this.teamRequestRepository = teamRequestRepository;
        this.gameRepository = gameRepository;
        this.eventPublisher = eventPublisher;
    }

    public TeamRequestResponse createTeamRequest(UUID userId, CreateTeamRequestDto request) {
        teamRequestRepository.findByUserId(userId, Pageable.unpaged())
            .forEach(r -> {
                if (r.getStatus().equals("open")) {
                    throw new BusinessException("Bạn đã có yêu cầu đang mở. Hãy đóng yêu cầu cũ trước.");
                }
            });

        TeamRequest teamRequest = doCreateTeamRequest(userId, request);

        eventPublisher.publish(EventType.TEAM_REQUEST_MATCHED, Map.of(
            "requestId", teamRequest.getId(),
            "userId", userId,
            "gameId", teamRequest.getGameId()
        ));

        return TeamRequestResponse.from(teamRequest);
    }

    @Transactional
    protected TeamRequest doCreateTeamRequest(UUID userId, CreateTeamRequestDto request) {
        TeamRequest teamRequest = new TeamRequest();
        teamRequest.setUserId(userId);
        teamRequest.setGameId(request.gameId());
        teamRequest.setRequiredRank(request.requiredRank());
        teamRequest.setRequiredRoles(request.requiredRoles());
        teamRequest.setRequireMic(request.requireMic());
        teamRequest.setDescription(request.description());
        teamRequest.setStatus("open");
        return teamRequestRepository.save(teamRequest);
    }

    @Transactional(readOnly = true)
    public PageResponse<TeamRequestResponse> getMyRequests(UUID userId, Pageable pageable) {
        Page<TeamRequest> requests = teamRequestRepository.findByUserId(userId, pageable);
        return PageResponse.from(requests.map(TeamRequestResponse::from));
    }

    @Transactional(readOnly = true)
    public PageResponse<TeamRequestResponse> getOpenRequests(UUID gameId, Pageable pageable) {
        Page<TeamRequest> requests;
        if (gameId != null) {
            requests = teamRequestRepository.findByGameIdAndStatus(gameId, "open", pageable);
        } else {
            requests = teamRequestRepository.findByStatus("open", pageable);
        }
        return PageResponse.from(requests.map(TeamRequestResponse::from));
    }

    @Transactional
    public void closeTeamRequest(UUID userId, UUID requestId) {
        TeamRequest request = teamRequestRepository.findById(requestId)
            .orElseThrow(() -> new ResourceNotFoundException("Team request", "id", requestId));

        if (!request.getUserId().equals(userId)) {
            throw new BusinessException("Bạn không có quyền đóng yêu cầu này");
        }

        request.setStatus("closed");
        teamRequestRepository.save(request);
    }
}
