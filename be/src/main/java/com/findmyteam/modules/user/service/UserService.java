package com.findmyteam.modules.user.service;

import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.common.exception.ResourceNotFoundException;
import com.findmyteam.modules.auth.entity.User;
import com.findmyteam.modules.auth.repository.UserRepository;
import com.findmyteam.modules.game.entity.Game;
import com.findmyteam.modules.game.repository.GameRepository;
import com.findmyteam.modules.user.dto.AddGameProfileRequest;
import com.findmyteam.modules.user.dto.UpdateProfileRequest;
import com.findmyteam.modules.user.dto.UserGameProfileResponse;
import com.findmyteam.modules.user.dto.UserProfileResponse;
import com.findmyteam.modules.user.entity.UserGameProfile;
import com.findmyteam.modules.user.repository.UserGameProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final UserGameProfileRepository userGameProfileRepository;
    private final GameRepository gameRepository;

    public UserService(UserRepository userRepository,
                      UserGameProfileRepository userGameProfileRepository,
                      GameRepository gameRepository) {
        this.userRepository = userRepository;
        this.userGameProfileRepository = userGameProfileRepository;
        this.gameRepository = gameRepository;
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(UUID userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        List<UserGameProfile> profiles = userGameProfileRepository.findByUserId(userId);

        return UserProfileResponse.from(user, profiles, null);
    }

    @Transactional
    public UserProfileResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        if (request.displayName() != null) {
            user.setDisplayName(request.displayName());
        }
        if (request.avatarUrl() != null) {
            user.setAvatarUrl(request.avatarUrl());
        }
        if (request.bio() != null) {
            user.setBio(request.bio());
        }
        if (request.region() != null) {
            user.setRegion(request.region());
        }

        user = userRepository.save(user);

        List<UserGameProfile> profiles = userGameProfileRepository.findByUserId(userId);

        return UserProfileResponse.from(user, profiles, null);
    }

    @Transactional
    public UserGameProfileResponse addGameProfile(UUID userId, AddGameProfileRequest request) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        Game game = gameRepository.findById(request.gameId())
            .orElseThrow(() -> new ResourceNotFoundException("Game", "id", request.gameId()));

        var existing = userGameProfileRepository.findByUserIdAndGameId(userId, request.gameId());
        if (existing.isPresent()) {
            throw new BusinessException("Bạn đã có profile cho game này");
        }

        if (request.isPrimary()) {
            userGameProfileRepository.findByUserId(userId).forEach(p -> {
                p.setPrimary(false);
                userGameProfileRepository.save(p);
            });
        }

        UserGameProfile profile = new UserGameProfile();
        profile.setUserId(userId);
        profile.setGameId(request.gameId());
        profile.setRank(request.rank());
        profile.setRole(request.role());
        profile.setHasMic(request.hasMic());
        profile.setPrimary(request.isPrimary());
        profile = userGameProfileRepository.save(profile);

        return UserGameProfileResponse.from(profile, game);
    }

    @Transactional
    public void removeGameProfile(UUID userId, UUID profileId) {
        UserGameProfile profile = userGameProfileRepository.findById(profileId)
            .orElseThrow(() -> new ResourceNotFoundException("Game profile", "id", profileId));

        if (!profile.getUserId().equals(userId)) {
            throw new BusinessException("Bạn không có quyền xóa profile này");
        }

        userGameProfileRepository.delete(profile);
    }

    @Transactional(readOnly = true)
    public User getCurrentUser(UUID userId) {
        return userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
    }
}
