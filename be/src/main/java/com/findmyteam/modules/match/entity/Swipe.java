package com.findmyteam.modules.match.entity;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "swipes")
public class Swipe {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "swiper_id", nullable = false)
    private UUID swiperId;

    @Column(name = "target_id", nullable = false)
    private UUID targetId;

    @Column(name = "direction", nullable = false, length = 10)
    private String direction;

    @Column(name = "game_id")
    private UUID gameId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "swiper_id", insertable = false, updatable = false)
    private com.findmyteam.modules.auth.entity.User swiper;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "target_id", insertable = false, updatable = false)
    private com.findmyteam.modules.auth.entity.User target;

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

    public UUID getSwiperId() {
        return swiperId;
    }

    public void setSwiperId(UUID swiperId) {
        this.swiperId = swiperId;
    }

    public UUID getTargetId() {
        return targetId;
    }

    public void setTargetId(UUID targetId) {
        this.targetId = targetId;
    }

    public String getDirection() {
        return direction;
    }

    public void setDirection(String direction) {
        this.direction = direction;
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

    public com.findmyteam.modules.auth.entity.User getSwiper() {
        return swiper;
    }

    public void setSwiper(com.findmyteam.modules.auth.entity.User swiper) {
        this.swiper = swiper;
    }

    public com.findmyteam.modules.auth.entity.User getTarget() {
        return target;
    }

    public void setTarget(com.findmyteam.modules.auth.entity.User target) {
        this.target = target;
    }
}
