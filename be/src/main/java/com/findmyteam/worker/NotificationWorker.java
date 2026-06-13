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
import org.springframework.data.redis.listener.PatternTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class NotificationWorker implements MessageListener {

    private static final Logger log = LoggerFactory.getLogger(NotificationWorker.class);

    private final RedisMessageListenerContainer listenerContainer;
    private final PresenceService presenceService;
    private final CommunityMemberRepository communityMemberRepository;
    private final ObjectMapper objectMapper;

    public NotificationWorker(RedisMessageListenerContainer listenerContainer,
                             PresenceService presenceService,
                             CommunityMemberRepository communityMemberRepository,
                             ObjectMapper objectMapper) {
        this.listenerContainer = listenerContainer;
        this.presenceService = presenceService;
        this.communityMemberRepository = communityMemberRepository;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    public void init() {
        listenerContainer.addMessageListener(this, new PatternTopic("events:*"));
        log.info("NotificationWorker initialized");
    }

    @Override
    public void onMessage(Message message, byte[] pattern) {
        try {
            String channel = new String(message.getChannel());
            String payload = new String(message.getBody());

            log.debug("NotificationWorker received: channel={}, payload={}", channel, payload);

            Map<String, Object> eventData = objectMapper.readValue(payload, Map.class);
            String eventType = (String) eventData.get("type");
            Map<String, Object> data = (Map<String, Object>) eventData.get("data");

            handleNotificationEvent(channel, eventType, data);

        } catch (Exception e) {
            log.error("Error processing notification: {}", e.getMessage(), e);
        }
    }

    private void handleNotificationEvent(String channel, String eventType, Map<String, Object> data) {
        if (channel.startsWith("events:team:")) {
            handleTeamEvent(eventType, data);
        } else if (channel.startsWith("events:community:")) {
            handleCommunityEvent(eventType, data);
        } else if (channel.startsWith("events:channel:")) {
            handleChannelEvent(eventType, data);
        } else {
            log.debug("Ignoring event for notification: {}", eventType);
        }
    }

    private void handleTeamEvent(String eventType, Map<String, Object> data) {
        log.debug("Team event: {} - data: {}", eventType, data);
    }

    private void handleCommunityEvent(String eventType, Map<String, Object> data) {
        log.debug("Community event: {} - data: {}", eventType, data);
    }

    private void handleChannelEvent(String eventType, Map<String, Object> data) {
        log.debug("Channel event: {} - data: {}", eventType, data);
    }
}
