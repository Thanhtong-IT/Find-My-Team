package com.findmyteam.websocket;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RoomManager {

    private final Map<String, Map<String, SessionInfo>> rooms = new ConcurrentHashMap<>();
    private final Map<String, SessionInfo> sessionMap = new ConcurrentHashMap<>();

    public void joinRoom(String roomId, String sessionId, String userId) {
        rooms.computeIfAbsent(roomId, k -> new ConcurrentHashMap<>())
             .put(sessionId, new SessionInfo(sessionId, userId));
    }

    public void leaveRoom(String roomId, String sessionId) {
        Map<String, SessionInfo> room = rooms.get(roomId);
        if (room != null) {
            room.remove(sessionId);
            if (room.isEmpty()) {
                rooms.remove(roomId);
            }
        }
    }

    public Set<String> getSessionIdsInRoom(String roomId) {
        Map<String, SessionInfo> room = rooms.get(roomId);
        return room != null ? room.keySet() : Set.of();
    }

    public Set<String> getUserIdsInRoom(String roomId) {
        Map<String, SessionInfo> room = rooms.get(roomId);
        if (room == null) return Set.of();
        return room.values().stream()
            .map(info -> info.userId)
            .collect(java.util.stream.Collectors.toSet());
    }

    public void registerSession(String sessionId, String userId) {
        sessionMap.put(sessionId, new SessionInfo(sessionId, userId));
    }

    public void removeSession(String sessionId) {
        SessionInfo info = sessionMap.remove(sessionId);
        if (info != null) {
            rooms.values().forEach(room -> room.remove(sessionId));
        }
    }

    public SessionInfo getSessionInfo(String sessionId) {
        return sessionMap.get(sessionId);
    }

    public record SessionInfo(String sessionId, String userId) {}
}
