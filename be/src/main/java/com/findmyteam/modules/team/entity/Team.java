package com.findmyteam.modules.team.entity;

import io.hypersistence.utils.hibernate.type.json.JsonType;
import jakarta.persistence.*;
import org.hibernate.annotations.Type;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "teams")
public class Team {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "name", length = 100)
    private String name;

    @Column(name = "game_id", nullable = false)
    private UUID gameId;

    @Column(name = "required_rank", length = 50)
    private String requiredRank;

    @Column(name = "max_size", nullable = false)
    private int maxSize = 5;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Type(JsonType.class)
    @Column(name = "required_roles", columnDefinition = "jsonb")
    private List<String> requiredRoles;

    @Column(name = "require_mic", nullable = false)
    private boolean requireMic = false;

    @Column(name = "status", nullable = false, length = 20)
    private String status = "recruiting";

    @Column(name = "owner_id", nullable = false)
    private UUID ownerId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "game_id", insertable = false, updatable = false)
    private com.findmyteam.modules.game.entity.Game game;

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

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public UUID getGameId() {
        return gameId;
    }

    public void setGameId(UUID gameId) {
        this.gameId = gameId;
    }

    public String getRequiredRank() {
        return requiredRank;
    }

    public void setRequiredRank(String requiredRank) {
        this.requiredRank = requiredRank;
    }

    public int getMaxSize() {
        return maxSize;
    }

    public void setMaxSize(int maxSize) {
        this.maxSize = maxSize;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public List<String> getRequiredRoles() {
        return requiredRoles;
    }

    public void setRequiredRoles(List<String> requiredRoles) {
        this.requiredRoles = requiredRoles;
    }

    public boolean isRequireMic() {
        return requireMic;
    }

    public void setRequireMic(boolean requireMic) {
        this.requireMic = requireMic;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public UUID getOwnerId() {
        return ownerId;
    }

    public void setOwnerId(UUID ownerId) {
        this.ownerId = ownerId;
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

    public com.findmyteam.modules.game.entity.Game getGame() {
        return game;
    }

    public void setGame(com.findmyteam.modules.game.entity.Game game) {
        this.game = game;
    }
}
