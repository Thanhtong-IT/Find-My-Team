package com.findmyteam.common.event;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class EventPublisher {

    private static final Logger log = LoggerFactory.getLogger(EventPublisher.class);

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    public EventPublisher(StringRedisTemplate redisTemplate, ObjectMapper objectMapper) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
    }

    /**
     * Publish event vào Redis Pub/Sub.
     * GỌI SAU KHI @Transactional COMMIT, KHÔNG BAO GIỜ GỌI TRONG TRANSACTION.
     */
    public void publish(EventType eventType, Map<String, Object> data) {
        if (org.springframework.transaction.support.TransactionSynchronizationManager.isActualTransactionActive()) {
            log.debug("Transaction active, registering post-commit synchronization for event {}", eventType);
            org.springframework.transaction.support.TransactionSynchronizationManager.registerSynchronization(
                new org.springframework.transaction.support.TransactionSynchronization() {
                    @Override
                    public void afterCommit() {
                        doPublish(eventType, data);
                    }
                }
            );
        } else {
            doPublish(eventType, data);
        }
    }

    private void doPublish(EventType eventType, Map<String, Object> data) {
        try {
            EventMessage message = new EventMessage(eventType.name(), data);
            String json = objectMapper.writeValueAsString(message);

            String channel = resolveChannel(eventType, data);
            redisTemplate.convertAndSend(channel, json);

            log.info("=== EVENT PUBLISHED === type={}, channel={}, data={}", eventType, channel, data.keySet());
        } catch (Exception e) {
            log.error("Failed to publish event {}: {}", eventType, e.getMessage(), e);
        }
    }

    private String resolveChannel(EventType eventType, Map<String, Object> data) {
        return switch (eventType) {
            case MESSAGE_CREATED -> "events:channel:" + data.get("channelId");
            case TEAM_MESSAGE_CREATED -> "events:team:" + data.get("teamId");
            case TEAM_MEMBER_JOINED, TEAM_MEMBER_LEFT, TEAM_MEMBER_READY ->
                "events:team:" + data.get("teamId");
            case TEAM_CREATED, TEAM_DISBANDED ->
                "events:global";
            case TEAM_MEMBER_KICKED ->
                "events:user:" + data.get("userId");
            case NOTIFICATION_NEW, JOIN_REQUEST_ACCEPTED, JOIN_REQUEST_REJECTED,
                 MATCH_CREATED, INVITATION_RECEIVED ->
                "events:user:" + data.get("userId");
            case JOIN_REQUEST_CREATED -> "events:user:" + data.get("ownerId");
            case COMMUNITY_MEMBER_JOINED -> "events:community:" + data.get("communityId");
            default -> "events:global";
        };
    }

    public record EventMessage(String type, Map<String, Object> data) {}
}
