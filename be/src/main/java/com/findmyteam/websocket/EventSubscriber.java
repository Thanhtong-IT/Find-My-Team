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
    }

    public void subscribeToChannel(String channel) {
        listenerContainer.addMessageListener(this, new ChannelTopic(channel));
        log.debug("Subscribed to Redis channel: {}", channel);
    }

    public void subscribeToUserChannel(UUID userId) {
        String channel = "events:user:" + userId;
        listenerContainer.addMessageListener(this, new ChannelTopic(channel));
        log.debug("Subscribed to user channel: {}", channel);
    }

    public void subscribeToTeamChannel(UUID teamId) {
        String channel = "events:team:" + teamId;
        listenerContainer.addMessageListener(this, new ChannelTopic(channel));
        log.debug("Subscribed to team channel: {}", channel);
    }

    public void subscribeToChannelChannel(UUID channelId) {
        String channel = "events:channel:" + channelId;
        listenerContainer.addMessageListener(this, new ChannelTopic(channel));
        log.debug("Subscribed to channel events channel: {}", channel);
    }

    @Override
    public void onMessage(Message message, byte[] pattern) {
        try {
            String channel = new String(message.getChannel());
            String payload = new String(message.getBody());

            log.debug("Received Redis message on channel {}: {}", channel, payload);

            Map<String, Object> eventData = objectMapper.readValue(payload, Map.class);
            String eventType = (String) eventData.get("type");
            Map<String, Object> data = (Map<String, Object>) eventData.get("data");

            handleEvent(channel, eventType, data);

        } catch (Exception e) {
            log.error("Failed to process Redis message: {}", e.getMessage(), e);
        }
    }

    private void handleEvent(String channel, String eventType, Map<String, Object> data) {
        if (channel.startsWith("events:user:")) {
            String userId = channel.substring("events:user:".length());
            webSocketHandler.broadcastToRoom("user:" + userId, Map.of(
                "type", eventType,
                "data", data
            ));
        } else if (channel.startsWith("events:team:")) {
            String teamId = channel.substring("events:team:".length());
            webSocketHandler.broadcastToRoom("room:team:" + teamId, Map.of(
                "type", eventType,
                "data", data
            ));
        } else if (channel.startsWith("events:channel:")) {
            String channelId = channel.substring("events:channel:".length());
            webSocketHandler.broadcastToRoom("room:channel:" + channelId, Map.of(
                "type", eventType,
                "data", data
            ));
        } else if (channel.startsWith("events:community:")) {
            String communityId = channel.substring("events:community:".length());
            webSocketHandler.broadcastToRoom("room:community:" + communityId, Map.of(
                "type", eventType,
                "data", data
            ));
        } else {
            log.warn("Unknown channel pattern: {}", channel);
        }
    }
}
