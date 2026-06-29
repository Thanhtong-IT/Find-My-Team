package com.findmyteam.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.data.redis.listener.ChannelTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.util.Map;
import java.util.UUID;

@Component
public class EventSubscriber implements MessageListener {

    private static final Logger log = LoggerFactory.getLogger(EventSubscriber.class);

    private final RedisMessageListenerContainer listenerContainer;
    private final FindMyTeamWebSocketHandler webSocketHandler;
    private final ObjectMapper objectMapper;

    public EventSubscriber(RedisMessageListenerContainer listenerContainer,
                          FindMyTeamWebSocketHandler webSocketHandler,
                          ObjectMapper objectMapper) {
        this.listenerContainer = listenerContainer;
        this.webSocketHandler = webSocketHandler;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    public void init() {
        subscribeToChannel("events:global");
        log.info("EventSubscriber initialized, subscribed to events:global");
    }

    public void subscribeToChannel(String channel) {
        listenerContainer.addMessageListener(this, new ChannelTopic(channel));
        log.info("Redis listener added for channel: {}", channel);
    }

    public void subscribeToUserChannel(UUID userId) {
        String channel = "events:user:" + userId;
        listenerContainer.addMessageListener(this, new ChannelTopic(channel));
        log.info("Redis listener added for events:user:{}", userId);
    }

    public void subscribeToTeamChannel(UUID teamId) {
        String channel = "events:team:" + teamId;
        listenerContainer.addMessageListener(this, new ChannelTopic(channel));
        log.info("Redis listener added for events:team:{}", teamId);
    }

    public void subscribeToChannelChannel(UUID channelId) {
        String channel = "events:channel:" + channelId;
        listenerContainer.addMessageListener(this, new ChannelTopic(channel));
        log.info("Redis listener added for events:channel:{}", channelId);
    }

    @Override
    public void onMessage(Message message, byte[] pattern) {
        try {
            String channel = new String(message.getChannel());
            String payload = new String(message.getBody());

            log.info("=== REDIS EVENT RECEIVED ===");
            log.info("Channel: {}", channel);
            log.info("Payload: {}", payload);

            Map<String, Object> eventData = objectMapper.readValue(payload, Map.class);
            String eventType = (String) eventData.get("type");
            Map<String, Object> data = (Map<String, Object>) eventData.get("data");

            log.info("Parsed eventType: {}, data keys: {}", eventType, data != null ? data.keySet() : "null");

            handleEvent(channel, eventType, data);

        } catch (Exception e) {
            log.error("Failed to process Redis message: {}", e.getMessage(), e);
        }
    }

    private void handleEvent(String channel, String eventType, Map<String, Object> data) {
        String resolvedRoomId = resolveRoomId(channel);
        if (resolvedRoomId == null) {
            log.warn("Unknown channel pattern, cannot resolve room: {}", channel);
            return;
        }

        Map<String, Object> payload = Map.of(
            "type", eventType,
            "data", data
        );

        log.info("Broadcasting {} to room: {}", eventType, resolvedRoomId);
        webSocketHandler.broadcastToRoom(resolvedRoomId, payload);
    }

    private String resolveRoomId(String channel) {
        if (channel.equals("events:global")) {
            return "global";
        } else if (channel.startsWith("events:user:")) {
            String userId = channel.substring("events:user:".length());
            return "user:" + userId;
        } else if (channel.startsWith("events:team:")) {
            String teamId = channel.substring("events:team:".length());
            return "room:team:" + teamId;
        } else if (channel.startsWith("events:channel:")) {
            String channelId = channel.substring("events:channel:".length());
            return "room:channel:" + channelId;
        } else if (channel.startsWith("events:community:")) {
            String communityId = channel.substring("events:community:".length());
            return "room:community:" + communityId;
        }
        return null;
    }
}
