package com.findmyteam.modules.user.service;

import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.common.exception.ResourceNotFoundException;
import com.findmyteam.modules.auth.entity.User;
import com.findmyteam.modules.auth.repository.UserRepository;
import com.findmyteam.modules.community.entity.Community;
import com.findmyteam.modules.community.entity.CommunityMember;
import com.findmyteam.modules.community.repository.CommunityMemberRepository;
import com.findmyteam.modules.community.repository.CommunityRepository;
import com.findmyteam.modules.game.entity.Game;
import com.findmyteam.modules.game.repository.GameRepository;
import com.findmyteam.modules.team.entity.Team;
import com.findmyteam.modules.team.entity.TeamMember;
import com.findmyteam.modules.team.repository.TeamMemberRepository;
import com.findmyteam.modules.team.repository.TeamRepository;
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
import java.util.Optional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final UserGameProfileRepository userGameProfileRepository;
    private final GameRepository gameRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final TeamRepository teamRepository;
    private final CommunityMemberRepository communityMemberRepository;
    private final CommunityRepository communityRepository;

    public UserService(UserRepository userRepository,
                      UserGameProfileRepository userGameProfileRepository,
                      GameRepository gameRepository,
                      TeamMemberRepository teamMemberRepository,
                      TeamRepository teamRepository,
                      CommunityMemberRepository communityMemberRepository,
                      CommunityRepository communityRepository) {
        this.userRepository = userRepository;
        this.userGameProfileRepository = userGameProfileRepository;
        this.gameRepository = gameRepository;
        this.teamMemberRepository = teamMemberRepository;
        this.teamRepository = teamRepository;
        this.communityMemberRepository = communityMemberRepository;
        this.communityRepository = communityRepository;
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(UUID userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        List<UserGameProfile> profiles = userGameProfileRepository.findByUserId(userId);

        // Find user's active team
        UserProfileResponse.TeamInfo currentTeam = findUserActiveTeam(userId);

        // Find user's communities
        List<CommunityMember> userCommunities = communityMemberRepository.findByUserId(userId);

        // Helper functions to get community and game names
        java.util.function.Function<UUID, String> getCommunityName = (communityId) ->
            communityRepository.findById(communityId).map(Community::getName).orElse(null);
        java.util.function.Function<UUID, String> getGameName = (communityId) ->
            communityRepository.findById(communityId)
                .map(c -> gameRepository.findById(c.getGameId()).map(Game::getName).orElse(null))
                .orElse(null);

        return UserProfileResponse.from(user, profiles, currentTeam, userCommunities, getCommunityName, getGameName);
    }

    private UserProfileResponse.TeamInfo findUserActiveTeam(UUID userId) {
        // Find any active team membership for this user
        List<TeamMember> memberships = teamMemberRepository.findByUserId(userId);
        
        for (TeamMember member : memberships) {
            if (TeamMember.STATUS_ACTIVE.equals(member.getStatus())) {
                // Fetch the team with game info
                Team team = teamRepository.findById(member.getTeamId()).orElse(null);
                if (team != null && !"disbanded".equals(team.getStatus())) {
                    String gameName = team.getGame() != null ? team.getGame().getName() : "Game";
                    return new UserProfileResponse.TeamInfo(
                        team.getId(),
                        team.getName(),
                        gameName,
                        member.getRole(),
                        member.isReady()
                    );
                }
            }
        }
        return null;
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

        UserProfileResponse.TeamInfo currentTeam = findUserActiveTeam(userId);

        // Find user's communities
        List<CommunityMember> userCommunities = communityMemberRepository.findByUserId(userId);

        // Helper functions to get community and game names
        java.util.function.Function<UUID, String> getCommunityName = (communityId) ->
            communityRepository.findById(communityId).map(Community::getName).orElse(null);
        java.util.function.Function<UUID, String> getGameName = (communityId) ->
            communityRepository.findById(communityId)
                .map(c -> gameRepository.findById(c.getGameId()).map(Game::getName).orElse(null))
                .orElse(null);

        return UserProfileResponse.from(user, profiles, currentTeam, userCommunities, getCommunityName, getGameName);
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
