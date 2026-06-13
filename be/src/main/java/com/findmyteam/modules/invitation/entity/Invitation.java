package com.findmyteam.modules.invitation.entity;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "invitations")
public class Invitation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "inviter_id", nullable = false)
    private UUID inviterId;

    @Column(name = "invitee_id", nullable = false)
    private UUID inviteeId;

    @Column(name = "team_id")
    private UUID teamId;

    @Column(name = "type", nullable = false, length = 20)
    private String type = "team_invite";

    @Column(name = "status", nullable = false, length = 20)
    private String status = "pending";

    @Column(name = "message", columnDefinition = "TEXT")
    private String message;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inviter_id", insertable = false, updatable = false)
    private com.findmyteam.modules.auth.entity.User inviter;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invitee_id", insertable = false, updatable = false)
    private com.findmyteam.modules.auth.entity.User invitee;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "team_id", insertable = false, updatable = false)
    private com.findmyteam.modules.team.entity.Team team;

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    // Getters and Setters
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getInviterId() {
        return inviterId;
    }

    public void setInviterId(UUID inviterId) {
        this.inviterId = inviterId;
    }

    public UUID getInviteeId() {
        return inviteeId;
    }

    public void setInviteeId(UUID inviteeId) {
        this.inviteeId = inviteeId;
    }

    public UUID getTeamId() {
        return teamId;
    }

    public void setTeamId(UUID teamId) {
        this.teamId = teamId;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public com.findmyteam.modules.auth.entity.User getInviter() {
        return inviter;
    }

    public void setInviter(com.findmyteam.modules.auth.entity.User inviter) {
        this.inviter = inviter;
    }

    public com.findmyteam.modules.auth.entity.User getInvitee() {
        return invitee;
    }

    public void setInvitee(com.findmyteam.modules.auth.entity.User invitee) {
        this.invitee = invitee;
    }

    public com.findmyteam.modules.team.entity.Team getTeam() {
        return team;
    }

    public void setTeam(com.findmyteam.modules.team.entity.Team team) {
        this.team = team;
    }
}
