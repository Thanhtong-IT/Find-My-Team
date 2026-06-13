package com.findmyteam.modules.invitation.dto;

import com.findmyteam.modules.invitation.entity.Invitation;
import java.time.OffsetDateTime;
import java.util.UUID;

public record InvitationResponse(
    UUID id,
    UUID inviterId,
    String inviterUsername,
    String inviterDisplayName,
    String inviterAvatarUrl,
    UUID inviteeId,
    UUID teamId,
    String teamName,
    String type,
    String status,
    String message,
    OffsetDateTime createdAt
) {
    public static InvitationResponse from(Invitation invitation) {
        return new InvitationResponse(
            invitation.getId(),
            invitation.getInviterId(),
            invitation.getInviter() != null ? invitation.getInviter().getUsername() : null,
            invitation.getInviter() != null ? invitation.getInviter().getDisplayName() : null,
            invitation.getInviter() != null ? invitation.getInviter().getAvatarUrl() : null,
            invitation.getInviteeId(),
            invitation.getTeamId(),
            invitation.getTeam() != null ? invitation.getTeam().getName() : null,
            invitation.getType(),
            invitation.getStatus(),
            invitation.getMessage(),
            invitation.getCreatedAt()
        );
    }
}
