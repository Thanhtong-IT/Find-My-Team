package com.findmyteam.modules.match.entity;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "matches")
public class Match {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_a_id", nullable = false)
    private UUID userAId;

    @Column(name = "user_b_id", nullable = false)
    private UUID userBId;

    @Column(name = "game_id")
    private UUID gameId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_a_id", insertable = false, updatable = false)
    private com.findmyteam.modules.auth.entity.User userA;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_b_id", insertable = false, updatable = false)
    private com.findmyteam.modules.auth.entity.User userB;

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }

    // Getters and Setters
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getUserAId() {
        return userAId;
    }

    public void setUserAId(UUID userAId) {
        this.userAId = userAId;
    }

    public UUID getUserBId() {
        return userBId;
    }

    public void setUserBId(UUID userBId) {
        this.userBId = userBId;
    }

    public UUID getGameId() {
        return gameId;
    }

    public void setGameId(UUID gameId) {
        this.gameId = gameId;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public com.findmyteam.modules.auth.entity.User getUserA() {
        return userA;
    }

    public void setUserA(com.findmyteam.modules.auth.entity.User userA) {
        this.userA = userA;
    }

    public com.findmyteam.modules.auth.entity.User getUserB() {
        return userB;
    }

    public void setUserB(com.findmyteam.modules.auth.entity.User userB) {
        this.userB = userB;
    }
}
