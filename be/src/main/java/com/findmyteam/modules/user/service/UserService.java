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
import com.findmyteam.modules.user.dto.GameProfileUpsertRequest;
import com.findmyteam.modules.user.dto.UpdateGameProfilesRequest;
import com.findmyteam.modules.user.dto.UpdateProfileRequest;
import com.findmyteam.modules.user.dto.UserGameProfileResponse;
import com.findmyteam.modules.user.dto.UserProfileResponse;
import com.findmyteam.modules.user.dto.VerifyRiotAccountRequest;
import com.findmyteam.modules.user.entity.RankSource;
import com.findmyteam.modules.user.entity.RiotVerificationStatus;
import com.findmyteam.modules.user.entity.UserGameProfile;
import com.findmyteam.modules.user.repository.UserGameProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final UserGameProfileRepository userGameProfileRepository;
    private final GameRepository gameRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final TeamRepository teamRepository;
    private final CommunityMemberRepository communityMemberRepository;
    private final CommunityRepository communityRepository;
    private final RiotApiService riotApiService;

    public UserService(UserRepository userRepository,
                      UserGameProfileRepository userGameProfileRepository,
                      GameRepository gameRepository,
                      TeamMemberRepository teamMemberRepository,
                      TeamRepository teamRepository,
                      CommunityMemberRepository communityMemberRepository,
                      CommunityRepository communityRepository,
                      RiotApiService riotApiService) {
        this.userRepository = userRepository;
        this.userGameProfileRepository = userGameProfileRepository;
        this.gameRepository = gameRepository;
        this.teamMemberRepository = teamMemberRepository;
        this.teamRepository = teamRepository;
        this.communityMemberRepository = communityMemberRepository;
        this.communityRepository = communityRepository;
        this.riotApiService = riotApiService;
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(UUID userId) {
        User user = findUser(userId);
        return buildProfileResponse(user);
    }

    private User findUser(UUID userId) {
        return userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
    }

    private UserGameProfile findOwnedGameProfile(UUID userId, UUID profileId) {
        return userGameProfileRepository.findByIdAndUserId(profileId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Game profile", "id", profileId));
    }

    private UserProfileResponse buildProfileResponse(User user) {
        UUID userId = user.getId();
        List<UserGameProfile> profiles = userGameProfileRepository.findByUserId(userId);
        UserProfileResponse.TeamInfo currentTeam = findUserActiveTeam(userId);
        List<CommunityMember> userCommunities = communityMemberRepository.findByUserId(userId);

        java.util.function.Function<UUID, String> getCommunityName = (communityId) ->
            communityRepository.findById(communityId).map(Community::getName).orElse(null);
        java.util.function.Function<UUID, String> getGameName = (communityId) ->
            communityRepository.findById(communityId)
                .map(c -> gameRepository.findById(c.getGameId()).map(Game::getName).orElse(null))
                .orElse(null);

        return UserProfileResponse.from(user, profiles, currentTeam, userCommunities, getCommunityName, getGameName);
    }

    private UserProfileResponse.TeamInfo findUserActiveTeam(UUID userId) {
        List<TeamMember> memberships = teamMemberRepository.findByUserId(userId);

        for (TeamMember member : memberships) {
            if (TeamMember.STATUS_ACTIVE.equals(member.getStatus())) {
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
        User user = findUser(userId);

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
        return buildProfileResponse(user);
    }

    @Transactional
    public UserProfileResponse updateGameProfiles(UUID userId, UpdateGameProfilesRequest request) {
        User user = findUser(userId);
        List<GameProfileUpsertRequest> requestedProfiles = request.profiles() == null ? List.of() : request.profiles();
        List<UserGameProfile> existingProfiles = userGameProfileRepository.findByUserId(userId);
        Map<UUID, UserGameProfile> existingProfilesByGameId = new HashMap<>();
        for (UserGameProfile existingProfile : existingProfiles) {
            existingProfilesByGameId.put(existingProfile.getGameId(), existingProfile);
        }

        Set<UUID> requestedGameIds = new HashSet<>();
        boolean primarySeen = false;
        List<UserGameProfile> profilesToSave = new ArrayList<>();

        for (GameProfileUpsertRequest item : requestedProfiles) {
            if (item == null) {
                throw new BusinessException("Dữ liệu game profile không hợp lệ");
            }
            if (!requestedGameIds.add(item.gameId())) {
                throw new BusinessException("Mỗi game chỉ được xuất hiện một lần");
            }

            Game game = gameRepository.findById(item.gameId())
                .orElseThrow(() -> new ResourceNotFoundException("Game", "id", item.gameId()));

            if (item.isPrimary()) {
                if (primarySeen) {
                    throw new BusinessException("Chỉ một game profile có thể là profile chính");
                }
                primarySeen = true;
            }

            UserGameProfile profile = existingProfilesByGameId.get(item.gameId());
            if (profile == null) {
                profile = new UserGameProfile();
                profile.setUserId(userId);
                profile.setGameId(item.gameId());
                profile.setRank(item.rank());
            } else if (item.id() != null && !item.id().equals(profile.getId())) {
                throw new BusinessException("Game profile không hợp lệ cho game đã chọn");
            }

            applyEditableFields(profile, game, item);
            profilesToSave.add(profile);
        }

        List<UserGameProfile> profilesToDelete = existingProfiles.stream()
            .filter(profile -> !requestedGameIds.contains(profile.getGameId()))
            .toList();

        if (!profilesToDelete.isEmpty()) {
            userGameProfileRepository.deleteAllInBatch(profilesToDelete);
        }
        if (!profilesToSave.isEmpty()) {
            userGameProfileRepository.saveAll(profilesToSave);
        }

        return buildProfileResponse(user);
    }

    @Transactional
    public UserGameProfileResponse verifyRiotAccount(UUID userId, UUID profileId, VerifyRiotAccountRequest request) {
        UserGameProfile profile = findOwnedGameProfile(userId, profileId);
        UUID gameId = profile.getGameId();
        Game game = gameRepository.findById(gameId)
            .orElseThrow(() -> new ResourceNotFoundException("Game", "id", gameId));

        RiotApiService.RiotVerificationData verifiedData = riotApiService.verify(
            game,
            request.riotGameName(),
            request.riotTagLine(),
            request.region()
        );

        OffsetDateTime now = OffsetDateTime.now();
        profile.setRiotGameName(verifiedData.riotGameName());
        profile.setRiotTagLine(verifiedData.riotTagLine());
        profile.setRiotPuuid(verifiedData.puuid());
        profile.setRiotRegion(verifiedData.region());
        profile.setRiotVerificationStatus(RiotVerificationStatus.VERIFIED);
        profile.setRiotVerifiedAt(now);
        profile.setRiotProfileLastSyncedAt(now);
        profile.setVerifiedRank(verifiedData.verifiedRank());
        profile.setRankSource(RankSource.RIOT);

        profile = userGameProfileRepository.save(profile);
        return UserGameProfileResponse.from(profile, game);
    }

    @Transactional
    public UserGameProfileResponse refreshRiotAccount(UUID userId, UUID profileId) {
        UserGameProfile profile = findOwnedGameProfile(userId, profileId);
        UUID gameId = profile.getGameId();
        Game game = gameRepository.findById(gameId)
            .orElseThrow(() -> new ResourceNotFoundException("Game", "id", gameId));

        if (profile.getRiotPuuid() == null || profile.getRiotPuuid().isBlank()) {
            throw new BusinessException("Game profile này chưa được liên kết Riot account");
        }
        if (profile.getRiotRegion() == null || profile.getRiotRegion().isBlank()) {
            throw new BusinessException("Game profile này chưa có Riot region để đồng bộ");
        }

        RiotApiService.RiotVerificationData verifiedData = riotApiService.refresh(
            game,
            profile.getRiotPuuid(),
            profile.getRiotRegion(),
            profile.getRiotGameName(),
            profile.getRiotTagLine()
        );

        OffsetDateTime now = OffsetDateTime.now();
        profile.setRiotGameName(verifiedData.riotGameName());
        profile.setRiotTagLine(verifiedData.riotTagLine());
        profile.setRiotRegion(verifiedData.region());
        profile.setVerifiedRank(verifiedData.verifiedRank());
        profile.setRankSource(RankSource.RIOT);
        profile.setRiotVerificationStatus(RiotVerificationStatus.VERIFIED);
        profile.setRiotProfileLastSyncedAt(now);
        if (profile.getRiotVerifiedAt() == null) {
            profile.setRiotVerifiedAt(now);
        }

        profile = userGameProfileRepository.save(profile);
        return UserGameProfileResponse.from(profile, game);
    }

    @Transactional
    public UserGameProfileResponse unlinkRiotAccount(UUID userId, UUID profileId) {
        UserGameProfile profile = findOwnedGameProfile(userId, profileId);
        UUID gameId = profile.getGameId();
        Game game = gameRepository.findById(gameId)
            .orElseThrow(() -> new ResourceNotFoundException("Game", "id", gameId));

        profile.setRiotGameName(null);
        profile.setRiotTagLine(null);
        profile.setRiotPuuid(null);
        profile.setRiotRegion(null);
        profile.setRiotVerificationStatus(RiotVerificationStatus.UNVERIFIED);
        profile.setRiotVerifiedAt(null);
        profile.setRiotProfileLastSyncedAt(null);
        profile.setVerifiedRank(null);
        profile.setRankSource(RankSource.MANUAL);

        profile = userGameProfileRepository.save(profile);
        return UserGameProfileResponse.from(profile, game);
    }

    @Transactional
    public UserGameProfileResponse addGameProfile(UUID userId, AddGameProfileRequest request) {
        UUID effectiveUserId = findUser(userId).getId();

        Game game = gameRepository.findById(request.gameId())
            .orElseThrow(() -> new ResourceNotFoundException("Game", "id", request.gameId()));

        var existing = userGameProfileRepository.findByUserIdAndGameId(effectiveUserId, request.gameId());
        if (existing.isPresent()) {
            throw new BusinessException("Bạn đã có profile cho game này");
        }

        if (request.isPrimary()) {
            userGameProfileRepository.findByUserId(effectiveUserId).forEach(p -> {
                p.setPrimary(false);
                userGameProfileRepository.save(p);
            });
        }

        UserGameProfile profile = new UserGameProfile();
        profile.setUserId(effectiveUserId);
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
        return findUser(userId);
    }

    private void applyEditableFields(UserGameProfile profile, Game game, GameProfileUpsertRequest item) {
        profile.setRole(item.role());
        profile.setHasMic(item.hasMic());
        profile.setPrimary(item.isPrimary());

        boolean riotVerified = riotApiService.supports(game)
            && profile.getRankSource() == RankSource.RIOT
            && profile.getRiotVerificationStatus() == RiotVerificationStatus.VERIFIED;

        if (!riotVerified) {
            profile.setRank(item.rank());
        }
    }
}
