package com.findmyteam.modules.user.entity;

import jakarta.persistence.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "user_game_profiles")
public class UserGameProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "game_id", nullable = false)
    private UUID gameId;

    @Column(name = "rank", length = 50)
    private String rank;

    @Column(name = "verified_rank", length = 50)
    private String verifiedRank;

    @Enumerated(EnumType.STRING)
    @Column(name = "rank_source", nullable = false, length = 20)
    private RankSource rankSource = RankSource.MANUAL;

    @Column(name = "role", length = 50)
    private String role;

    @Column(name = "has_mic", nullable = false)
    private boolean hasMic = false;

    @Column(name = "is_primary", nullable = false)
    private boolean isPrimary = false;

    @Column(name = "riot_game_name", length = 100)
    private String riotGameName;

    @Column(name = "riot_tag_line", length = 20)
    private String riotTagLine;

    @Column(name = "riot_puuid", length = 100)
    private String riotPuuid;

    @Column(name = "riot_region", length = 20)
    private String riotRegion;

    @Enumerated(EnumType.STRING)
    @Column(name = "riot_verification_status", nullable = false, length = 20)
    private RiotVerificationStatus riotVerificationStatus = RiotVerificationStatus.UNVERIFIED;

    @Column(name = "riot_verified_at")
    private OffsetDateTime riotVerifiedAt;

    @Column(name = "riot_profile_last_synced_at")
    private OffsetDateTime riotProfileLastSyncedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    private com.findmyteam.modules.auth.entity.User user;

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

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public UUID getGameId() {
        return gameId;
    }

    public void setGameId(UUID gameId) {
        this.gameId = gameId;
    }

    public String getRank() {
        return rank;
    }

    public void setRank(String rank) {
        this.rank = rank;
    }

    public String getVerifiedRank() {
        return verifiedRank;
    }

    public void setVerifiedRank(String verifiedRank) {
        this.verifiedRank = verifiedRank;
    }

    public RankSource getRankSource() {
        return rankSource;
    }

    public void setRankSource(RankSource rankSource) {
        this.rankSource = rankSource;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public boolean isHasMic() {
        return hasMic;
    }

    public void setHasMic(boolean hasMic) {
        this.hasMic = hasMic;
    }

    public boolean isPrimary() {
        return isPrimary;
    }

    public void setPrimary(boolean primary) {
        isPrimary = primary;
    }

    public String getRiotGameName() {
        return riotGameName;
    }

    public void setRiotGameName(String riotGameName) {
        this.riotGameName = riotGameName;
    }

    public String getRiotTagLine() {
        return riotTagLine;
    }

    public void setRiotTagLine(String riotTagLine) {
        this.riotTagLine = riotTagLine;
    }

    public String getRiotPuuid() {
        return riotPuuid;
    }

    public void setRiotPuuid(String riotPuuid) {
        this.riotPuuid = riotPuuid;
    }

    public String getRiotRegion() {
        return riotRegion;
    }

    public void setRiotRegion(String riotRegion) {
        this.riotRegion = riotRegion;
    }

    public RiotVerificationStatus getRiotVerificationStatus() {
        return riotVerificationStatus;
    }

    public void setRiotVerificationStatus(RiotVerificationStatus riotVerificationStatus) {
        this.riotVerificationStatus = riotVerificationStatus;
    }

    public OffsetDateTime getRiotVerifiedAt() {
        return riotVerifiedAt;
    }

    public void setRiotVerifiedAt(OffsetDateTime riotVerifiedAt) {
        this.riotVerifiedAt = riotVerifiedAt;
    }

    public OffsetDateTime getRiotProfileLastSyncedAt() {
        return riotProfileLastSyncedAt;
    }

    public void setRiotProfileLastSyncedAt(OffsetDateTime riotProfileLastSyncedAt) {
        this.riotProfileLastSyncedAt = riotProfileLastSyncedAt;
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

    public com.findmyteam.modules.auth.entity.User getUser() {
        return user;
    }

    public void setUser(com.findmyteam.modules.auth.entity.User user) {
        this.user = user;
    }

    public com.findmyteam.modules.game.entity.Game getGame() {
        return game;
    }

    public void setGame(com.findmyteam.modules.game.entity.Game game) {
        this.game = game;
    }
}
