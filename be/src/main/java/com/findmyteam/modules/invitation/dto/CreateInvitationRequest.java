package com.findmyteam.modules.invitation.dto;

import jakarta.validation.constraints.Size;
import java.util.UUID;

public record CreateInvitationRequest(
    UUID inviteeId,

    UUID teamId,

    @Size(max = 500, message = "Tin nhắn tối đa 500 ký tự")
    String message
) {}
