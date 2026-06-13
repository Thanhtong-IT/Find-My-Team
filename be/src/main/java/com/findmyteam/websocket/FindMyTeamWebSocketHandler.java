package com.findmyteam.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class FindMyTeamWebSocketHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(FindMyTeamWebSocketHandler.class);

    private final RoomManager roomManager;
    private final PresenceService presenceService;
    private final ObjectMapper objectMapper;

    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    public FindMyTeamWebSocketHandler(RoomManager roomManager,
                                     PresenceService presenceService,
                                     ObjectMapper objectMapper) {
        this.roomManager = roomManager;
        this.presenceService = presenceService;
        this.objectMapper = objectMapper;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String userId = (String) session.getAttributes().get("userId");
        if (userId == null) {
            session.close(CloseStatus.POLICY_VIOLATION);
            return;
        }

        String sessionId = session.getId();
        sessions.put(sessionId, session);
        roomManager.registerSession(sessionId, userId);
        presenceService.setOnline(UUID.fromString(userId));

        log.info("WebSocket connected: userId={}, sessionId={}", userId, sessionId);

        sendMessage(session, new WsMessage("connected", Map.of(
            "sessionId", sessionId,
            "userId", userId
        )));

        subscribeToUserChannel(userId);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String payload = message.getPayload();
        WsMessage wsMessage = objectMapper.readValue(payload, WsMessage.class);

        switch (wsMessage.op) {
            case "heartbeat" -> handleHeartbeat(session);
            case "subscribe" -> handleSubscribe(session, wsMessage);
            case "unsubscribe" -> handleUnsubscribe(session, wsMessage);
            default -> log.warn("Unknown WebSocket op: {}", wsMessage.op);
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String userId = (String) session.getAttributes().get("userId");
        String sessionId = session.getId();

        if (userId != null) {
            presenceService.setOffline(UUID.fromString(userId));
            roomManager.removeSession(sessionId);
            log.info("WebSocket disconnected: userId={}, sessionId={}, status={}", userId, sessionId, status);
        }

        sessions.remove(sessionId);
    }

    private void handleHeartbeat(WebSocketSession session) {
        String userId = (String) session.getAttributes().get("userId");
        if (userId != null) {
            presenceService.heartbeat(UUID.fromString(userId));
        }
        sendMessage(session, new WsMessage("heartbeat_ack", Map.of()));
    }

    private void handleSubscribe(WebSocketSession session, WsMessage message) {
        String roomId = (String) message.data.get("roomId");
        String roomType = (String) message.data.get("roomType");

        if (roomId == null || roomType == null) return;

        String sessionId = session.getId();
        String userId = (String) session.getAttributes().get("userId");
        roomManager.joinRoom(roomId, sessionId, userId);

        switch (roomType) {
            case "team" -> presenceService.joinTeamRoom(UUID.fromString(userId), UUID.fromString(roomId));
            case "channel" -> presenceService.joinChannelRoom(UUID.fromString(userId), UUID.fromString(roomId));
        }

        log.debug("Session {} subscribed to {}:{}", sessionId, roomType, roomId);
    }

    private void handleUnsubscribe(WebSocketSession session, WsMessage message) {
        String roomId = (String) message.data.get("roomId");

        if (roomId == null) return;

        String sessionId = session.getId();
        roomManager.leaveRoom(roomId, sessionId);

        log.debug("Session {} unsubscribed from {}", sessionId, roomId);
    }

    public void broadcastToRoom(String roomId, Object payload) {
        Set<String> sessionIds = roomManager.getSessionIdsInRoom(roomId);
        for (String sessionId : sessionIds) {
            WebSocketSession session = sessions.get(sessionId);
            if (session != null && session.isOpen()) {
                sendMessage(session, new WsMessage("event", Map.of(
                    "roomId", roomId,
                    "data", payload
                )));
            }
        }
    }

    public void sendToUser(UUID userId, Object payload) {
        String userRoom = "user:" + userId;
        Set<String> sessionIds = roomManager.getSessionIdsInRoom(userRoom);
        for (String sessionId : sessionIds) {
            WebSocketSession session = sessions.get(sessionId);
            if (session != null && session.isOpen()) {
                sendMessage(session, new WsMessage("event", Map.of("data", payload)));
            }
        }
    }

    public void sendToSession(String sessionId, Object payload) {
        WebSocketSession session = sessions.get(sessionId);
        if (session != null && session.isOpen()) {
            sendMessage(session, new WsMessage("event", Map.of("data", payload)));
        }
    }

    private void subscribeToUserChannel(String userId) {
        String userRoom = "user:" + userId;
        roomManager.joinRoom(userRoom, userId, userId);
    }

    private void sendMessage(WebSocketSession session, WsMessage message) {
        try {
            String json = objectMapper.writeValueAsString(message);
            session.sendMessage(new TextMessage(json));
        } catch (IOException e) {
            log.error("Failed to send message: {}", e.getMessage());
        }
    }

    public record WsMessage(String op, Map<String, Object> data) {}
}
