package com.findmyteam.worker;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.findmyteam.modules.chat.entity.ConversationMember;
import com.findmyteam.modules.chat.repository.ConversationMemberRepository;
import com.findmyteam.modules.community.entity.CommunityMember;
import com.findmyteam.modules.community.repository.CommunityMemberRepository;
import com.findmyteam.websocket.PresenceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.data.redis.listener.ChannelTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.PostConstruct;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class UnreadCountWorker implements MessageListener {

    private static final Logger log = LoggerFactory.getLogger(UnreadCountWorker.class);

    private final RedisMessageListenerContainer listenerContainer;
    private final ConversationMemberRepository conversationMemberRepository;
    private final CommunityMemberRepository communityMemberRepository;
    private final PresenceService presenceService;
    private final ObjectMapper objectMapper;

    public UnreadCountWorker(RedisMessageListenerContainer listenerContainer,
                           ConversationMemberRepository conversationMemberRepository,
                           CommunityMemberRepository communityMemberRepository,
                           PresenceService presenceService,
                           ObjectMapper objectMapper) {
        this.listenerContainer = listenerContainer;
        this.conversationMemberRepository = conversationMemberRepository;
        this.communityMemberRepository = communityMemberRepository;
        this.presenceService = presenceService;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    public void init() {
        listenerContainer.addMessageListener(this, new org.springframework.data.redis.listener.PatternTopic("events:channel:*"));
        log.info("UnreadCountWorker initialized");
    }

    @Override
    public void onMessage(Message message, byte[] pattern) {
        try {
            String channel = new String(message.getChannel());
            String payload = new String(message.getBody());

            log.debug("UnreadCountWorker received: channel={}, payload={}", channel, payload);

            if (!channel.startsWith("events:channel:")) {
                return;
            }

            Map<String, Object> eventData = objectMapper.readValue(payload, Map.class);
            String eventType = (String) eventData.get("type");

            if ("MESSAGE_CREATED".equals(eventType)) {
                Map<String, Object> data = (Map<String, Object>) eventData.get("data");
                handleMessageCreated(data);
            }

        } catch (Exception e) {
            log.error("Error updating unread count: {}", e.getMessage(), e);
        }
    }

    @Transactional
    protected void handleMessageCreated(Map<String, Object> data) {
        UUID channelId = parseUUID(data.get("channelId"));
        UUID senderId = parseUUID(data.get("senderId"));
        UUID communityId = parseUUID(data.get("communityId"));

        if (channelId == null || communityId == null) {
            log.warn("Missing channelId or communityId in MESSAGE_CREATED event");
            return;
        }

        List<CommunityMember> members = communityMemberRepository.findByCommunityId(communityId);

        for (CommunityMember member : members) {
            if (member.getUserId().equals(senderId)) {
                continue;
            }

            if (presenceService.isOnline(member.getUserId())) {
                log.debug("User {} is online, skipping unread count update", member.getUserId());
                continue;
            }

            member.incrementUnreadCount();
            log.debug("Incremented unread count for user {} in community {}", member.getUserId(), communityId);
        }

        communityMemberRepository.saveAll(members);
    }

    private UUID parseUUID(Object obj) {
        if (obj == null) return null;
        if (obj instanceof UUID) return (UUID) obj;
        try {
            return UUID.fromString(obj.toString());
        } catch (Exception e) {
            return null;
        }
    }
}
