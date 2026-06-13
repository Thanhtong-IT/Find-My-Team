package com.findmyteam.modules.explore.service;

import com.findmyteam.modules.auth.entity.User;
import com.findmyteam.modules.auth.repository.UserRepository;
import com.findmyteam.modules.explore.dto.OnlinePlayerResponse;
import com.findmyteam.modules.user.entity.UserGameProfile;
import com.findmyteam.modules.user.repository.UserGameProfileRepository;
import com.findmyteam.websocket.PresenceService;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ExploreService {

    private final UserRepository userRepository;
    private final UserGameProfileRepository userGameProfileRepository;
    private final PresenceService presenceService;

    public ExploreService(UserRepository userRepository,
                         UserGameProfileRepository userGameProfileRepository,
                         PresenceService presenceService) {
        this.userRepository = userRepository;
        this.userGameProfileRepository = userGameProfileRepository;
        this.presenceService = presenceService;
    }

    @Transactional(readOnly = true)
    public List<OnlinePlayerResponse> getOnlinePlayers(UUID gameId, int limit) {
        Set<String> onlineUserIds = presenceService.getOnlineInRoom("global");

        if (onlineUserIds == null || onlineUserIds.isEmpty()) {
            return List.of();
        }

        List<User> users = userRepository.findAll().stream()
            .filter(u -> onlineUserIds.contains(u.getId().toString()))
            .limit(limit)
            .collect(Collectors.toList());

        return users.stream()
            .map(user -> {
                List<UserGameProfile> profiles = gameId != null
                    ? userGameProfileRepository.findByUserId(user.getId()).stream()
                        .filter(p -> p.getGameId().equals(gameId))
                        .collect(Collectors.toList())
                    : userGameProfileRepository.findByUserId(user.getId());

                return OnlinePlayerResponse.from(user, profiles);
            })
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<User> searchUsers(String query, int limit) {
        return userRepository.findByUsernameContainingIgnoreCaseOrFullNameContainingIgnoreCase(
            query, query, PageRequest.of(0, limit)
        ).getContent();
    }
}
