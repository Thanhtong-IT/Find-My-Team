package com.findmyteam.modules.community.service;

import com.findmyteam.common.dto.PageResponse;
import com.findmyteam.common.event.EventPublisher;
import com.findmyteam.common.event.EventType;
import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.common.exception.ResourceNotFoundException;
import com.findmyteam.modules.auth.entity.User;
import com.findmyteam.modules.auth.repository.UserRepository;
import com.findmyteam.modules.community.dto.*;
import com.findmyteam.modules.community.entity.*;
import com.findmyteam.modules.community.repository.*;
import com.findmyteam.modules.game.repository.GameRepository;
import com.findmyteam.websocket.EventSubscriber;
import com.findmyteam.websocket.PresenceService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class CommunityService {

    private final CommunityRepository communityRepository;
    private final ChannelRepository channelRepository;
    private final CommunityMemberRepository memberRepository;
    private final GameRepository gameRepository;
    private final UserRepository userRepository;
    private final EventPublisher eventPublisher;
    private final PresenceService presenceService;
    private final EventSubscriber eventSubscriber;

    public CommunityService(CommunityRepository communityRepository,
                          ChannelRepository channelRepository,
                          CommunityMemberRepository memberRepository,
                          GameRepository gameRepository,
                          UserRepository userRepository,
                          EventPublisher eventPublisher,
                          PresenceService presenceService,
                          EventSubscriber eventSubscriber) {
        this.communityRepository = communityRepository;
        this.channelRepository = channelRepository;
        this.memberRepository = memberRepository;
        this.gameRepository = gameRepository;
        this.userRepository = userRepository;
        this.eventPublisher = eventPublisher;
        this.presenceService = presenceService;
        this.eventSubscriber = eventSubscriber;
    }

    @Transactional(readOnly = true)
    public PageResponse<CommunityResponse> getPublicCommunities(UUID gameId, Pageable pageable) {
        Page<Community> communities;
        if (gameId != null) {
            communities = communityRepository.findByGameIdAndIsPublicTrue(gameId, pageable);
        } else {
            communities = communityRepository.findByIsPublicTrue(pageable);
        }

        Page<CommunityResponse> responsePage = communities.map(c -> {
            String gameName = gameRepository.findById(c.getGameId()).map(g -> g.getName()).orElse(null);
            String ownerName = userRepository.findById(c.getOwnerId()).map(u -> u.getDisplayName()).orElse(null);
            return CommunityResponse.from(c, gameName, ownerName);
        });

        return PageResponse.from(responsePage);
    }

    @Transactional
    public CommunityResponse createCommunity(UUID userId, CreateCommunityRequest request) {
        Community community = new Community();
        community.setName(request.name());
        community.setGameId(request.gameId());
        community.setDescription(request.description());
        community.setAvatarUrl(request.avatarUrl());
        community.setIsPublic(request.isPublic());
        community.setOwnerId(userId);
        community = communityRepository.save(community);

        CommunityMember owner = new CommunityMember();
        owner.setCommunityId(community.getId());
        owner.setUserId(userId);
        owner.setRole("owner");
        memberRepository.save(owner);

        Channel defaultChannel = new Channel();
        defaultChannel.setCommunityId(community.getId());
        defaultChannel.setName("general");
        defaultChannel.setType("text");
        defaultChannel.setPosition(0);
        channelRepository.save(defaultChannel);

        presenceService.joinRoom("room:community:" + community.getId(), userId);
        eventSubscriber.subscribeToChannel("events:community:" + community.getId());

        String gameName = gameRepository.findById(community.getGameId()).map(g -> g.getName()).orElse(null);
        return CommunityResponse.from(community, gameName, userRepository.findById(userId).map(u -> u.getDisplayName()).orElse(null));
    }

    @Transactional
    public void joinCommunity(UUID userId, UUID communityId) {
        Community community = communityRepository.findById(communityId)
            .orElseThrow(() -> new ResourceNotFoundException("Community", "id", communityId));

        if (memberRepository.existsByCommunityIdAndUserId(communityId, userId)) {
            throw new BusinessException("Bạn đã là thành viên");
        }

        doJoinCommunity(userId, communityId);

        eventPublisher.publish(EventType.COMMUNITY_MEMBER_JOINED, Map.of(
            "communityId", communityId,
            "userId", userId
        ));
    }

    @Transactional
    protected void doJoinCommunity(UUID userId, UUID communityId) {
        CommunityMember member = new CommunityMember();
        member.setCommunityId(communityId);
        member.setUserId(userId);
        member.setRole("member");
        memberRepository.save(member);

        presenceService.joinRoom("room:community:" + communityId, userId);
        eventSubscriber.subscribeToChannel("events:community:" + communityId);
    }

    @Transactional
    public void leaveCommunity(UUID userId, UUID communityId) {
        Community community = communityRepository.findById(communityId)
            .orElseThrow(() -> new ResourceNotFoundException("Community", "id", communityId));

        if (community.getOwnerId().equals(userId)) {
            throw new BusinessException("Chủ cộng đồng không thể rời");
        }

        memberRepository.deleteByCommunityIdAndUserId(communityId, userId);
        presenceService.leaveRoom("room:community:" + communityId, userId);
    }

    @Transactional(readOnly = true)
    public List<ChannelResponse> getChannels(UUID communityId) {
        return channelRepository.findByCommunityIdOrderByPositionAsc(communityId).stream()
            .map(ChannelResponse::from)
            .toList();
    }

    @Transactional
    public ChannelResponse createChannel(UUID userId, UUID communityId, CreateChannelRequest request) {
        Community community = communityRepository.findById(communityId)
            .orElseThrow(() -> new ResourceNotFoundException("Community", "id", communityId));

        if (!community.getOwnerId().equals(userId)) {
            throw new BusinessException("Chỉ chủ cộng đồng mới được tạo channel");
        }

        Channel channel = new Channel();
        channel.setCommunityId(communityId);
        channel.setName(request.name());
        channel.setType(request.type() != null ? request.type() : "text");
        channel.setPosition(channelRepository.getNextPosition(communityId));
        channel = channelRepository.save(channel);

        return ChannelResponse.from(channel);
    }
}
