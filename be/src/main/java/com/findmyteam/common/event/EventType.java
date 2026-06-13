package com.findmyteam.common.event;

public enum EventType {
    TEAM_CREATED,
    TEAM_MEMBER_JOINED,
    TEAM_MEMBER_LEFT,
    TEAM_DISBANDED,
    TEAM_MEMBER_READY,

    // Join request events
    JOIN_REQUEST_CREATED,
    JOIN_REQUEST_ACCEPTED,
    JOIN_REQUEST_REJECTED,

    // Match events
    MATCH_CREATED,

    // Notification events
    NOTIFICATION_NEW,

    // Invitation events
    INVITATION_RECEIVED,

    // Community events
    COMMUNITY_MEMBER_JOINED,

    // Team request events
    TEAM_REQUEST_MATCHED,

    // Message events
    MESSAGE_CREATED,

    // User presence events
    USER_ONLINE,
    USER_OFFLINE
}
