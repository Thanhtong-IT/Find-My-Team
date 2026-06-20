package com.findmyteam.modules.match.service;

import com.findmyteam.common.dto.PageResponse;
import com.findmyteam.common.event.EventPublisher;
import com.findmyteam.common.event.EventType;
import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.modules.match.dto.CreateSwipeRequest;
import com.findmyteam.modules.match.dto.MatchResponse;
import com.findmyteam.modules.match.entity.Match;
import com.findmyteam.modules.match.entity.Swipe;
import com.findmyteam.modules.match.repository.MatchRepository;
import com.findmyteam.modules.match.repository.SwipeRepository;
import com.findmyteam.modules.notification.service.NotificationService;
import com.findmyteam.modules.auth.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class MatchService {

    private final SwipeRepository swipeRepository;
    private final MatchRepository matchRepository;
    private final EventPublisher eventPublisher;
    private final NotificationService notificationService;
    private final UserRepository userRepository;

    public MatchService(SwipeRepository swipeRepository,
                      MatchRepository matchRepository,
                      EventPublisher eventPublisher,
                      NotificationService notificationService,
                      UserRepository userRepository) {
        this.swipeRepository = swipeRepository;
        this.matchRepository = matchRepository;
        this.eventPublisher = eventPublisher;
        this.notificationService = notificationService;
        this.userRepository = userRepository;
    }

    @Transactional
    public void createSwipe(UUID userId, CreateSwipeRequest request) {
        if (userId.equals(request.targetId())) {
            throw new BusinessException("Không thể tự swipe bản thân");
        }

        if (!"like".equals(request.direction()) && !"skip".equals(request.direction())) {
            throw new BusinessException("Direction phải là 'like' hoặc 'skip'");
        }

        doCreateSwipe(userId, request);

        if ("like".equals(request.direction())) {
            if (swipeRepository.hasLiked(request.targetId(), userId)) {
                createMatch(userId, request.targetId(), request.gameId());
            }
        }
    }

    @Transactional
    protected void doCreateSwipe(UUID userId, CreateSwipeRequest request) {
        Optional<Swipe> existing = swipeRepository
            .findBySwiperIdAndTargetIdAndGameId(userId, request.targetId(), request.gameId());

        if (existing.isPresent()) {
            Swipe swipe = existing.get();
            swipe.setDirection(request.direction());
            swipeRepository.save(swipe);
        } else {
            Swipe swipe = new Swipe();
            swipe.setSwiperId(userId);
            swipe.setTargetId(request.targetId());
            swipe.setDirection(request.direction());
            swipe.setGameId(request.gameId());
            swipeRepository.save(swipe);
        }
    }

    protected void createMatch(UUID userA, UUID userB, UUID gameId) {
        UUID userAId = userA.compareTo(userB) < 0 ? userA : userB;
        UUID userBId = userA.compareTo(userB) < 0 ? userB : userA;

        if (matchRepository.existsByUserAIdAndUserBId(userAId, userBId)) {
            return;
        }

        Match match = doCreateMatch(userAId, userBId, gameId);

        // Create notification for both users
        String userBName = userRepository.findById(userBId)
                .map(u -> u.getDisplayName() != null ? u.getDisplayName() : u.getUsername())
                .orElse("Người dùng");
        notificationService.createNotification(
                userAId,
                "match_created",
                "Ghép đôi thành công!",
                "Bạn và " + userBName + " đã ghép đôi thành công",
                match.getId().toString(),
                userBId.toString()
        );

        String userAName = userRepository.findById(userAId)
                .map(u -> u.getDisplayName() != null ? u.getDisplayName() : u.getUsername())
                .orElse("Người dùng");
        notificationService.createNotification(
                userBId,
                "match_created",
                "Ghép đôi thành công!",
                "Bạn và " + userAName + " đã ghép đôi thành công",
                match.getId().toString(),
                userAId.toString()
        );

        eventPublisher.publish(EventType.MATCH_CREATED, Map.of(
            "matchId", match.getId(),
            "userAId", userAId,
            "userBId", userBId
        ));
    }

    @Transactional
    protected Match doCreateMatch(UUID userAId, UUID userBId, UUID gameId) {
        Match match = new Match();
        match.setUserAId(userAId);
        match.setUserBId(userBId);
        match.setGameId(gameId);
        return matchRepository.save(match);
    }

    @Transactional(readOnly = true)
    public PageResponse<MatchResponse> getMatches(UUID userId, Pageable pageable) {
        Page<Match> matches = matchRepository.findByUserId(userId, pageable);
        return PageResponse.from(matches.map(MatchResponse::from));
    }
}
