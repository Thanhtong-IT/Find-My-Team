package com.findmyteam.websocket;

import com.findmyteam.common.event.EventPublisher;
import com.findmyteam.common.event.EventType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class PresenceService {

    private static final Logger log = LoggerFactory.getLogger(PresenceService.class);

    private static final Duration PRESENCE_TTL = Duration.ofSeconds(60);
    private static final Duration OFFLINE_GRACE_PERIOD = Duration.ofSeconds(5);

    private final StringRedisTemplate redis;
    private final EventPublisher eventPublisher;

    public PresenceService(StringRedisTemplate redis, EventPublisher eventPublisher) {
        this.redis = redis;
        this.eventPublisher = eventPublisher;
    }

    public void setOnline(UUID userId) {
        redis.opsForValue().set(
            "presence:user:" + userId, "online", PRESENCE_TTL
        );
        log.debug("User {} is online", userId);
    }

    public void heartbeat(UUID userId) {
        redis.expire("presence:user:" + userId, PRESENCE_TTL);
    }

    public void setOffline(UUID userId) {
        redis.delete("presence:user:" + userId);

        eventPublisher.publish(EventType.USER_OFFLINE, Map.of(
            "userId", userId
        ));
        log.debug("User {} is offline", userId);
    }

    public boolean isOnline(UUID userId) {
        return Boolean.TRUE.equals(
            redis.hasKey("presence:user:" + userId)
        );
    }

    public void joinRoom(String roomKey, UUID userId) {
        redis.opsForSet().add(roomKey, userId.toString());
        log.debug("User {} joined room {}", userId, roomKey);
    }

    public void leaveRoom(String roomKey, UUID userId) {
        redis.opsForSet().remove(roomKey, userId.toString());
        log.debug("User {} left room {}", userId, roomKey);
    }

    public Set<String> getOnlineInRoom(String roomKey) {
        Set<String> members = redis.opsForSet().members(roomKey);
        if (members == null) return Set.of();

        return members.stream()
            .filter(memberId -> isOnline(UUID.fromString(memberId)))
            .collect(java.util.stream.Collectors.toSet());
    }

    public void joinTeamRoom(UUID userId, UUID teamId) {
        joinRoom("room:team:" + teamId, userId);
    }

    public void leaveTeamRoom(UUID userId, UUID teamId) {
        leaveRoom("room:team:" + teamId, userId);
    }

    public void joinChannelRoom(UUID userId, UUID channelId) {
        joinRoom("room:channel:" + channelId, userId);
    }

    public void leaveChannelRoom(UUID userId, UUID channelId) {
        leaveRoom("room:channel:" + channelId, userId);
    }

    public Set<String> getOnlineTeamMembers(UUID teamId) {
        return getOnlineInRoom("room:team:" + teamId);
    }

    public Set<String> getOnlineChannelMembers(UUID channelId) {
        return getOnlineInRoom("room:channel:" + channelId);
    }
}
