package com.findmyteam.modules.game.entity;

import io.hypersistence.utils.hibernate.type.json.JsonType;
import jakarta.persistence.*;
import org.hibernate.annotations.Type;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "games")
public class Game {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "name", unique = true, nullable = false, length = 100)
    private String name;

    @Column(name = "short_name", length = 50)
    private String shortName;

    @Column(name = "tag", length = 50)
    private String tag;

    @Column(name = "gradient_start", length = 7)
    private String gradientStart;

    @Column(name = "gradient_end", length = 7)
    private String gradientEnd;

    @Column(name = "icon_url", length = 500)
    private String iconUrl;

    @Type(JsonType.class)
    @Column(name = "ranks", columnDefinition = "jsonb", nullable = false)
    private List<String> ranks = List.of();

    @Type(JsonType.class)
    @Column(name = "roles", columnDefinition = "jsonb", nullable = false)
    private List<String> roles = List.of();

    @Column(name = "max_team_size", nullable = false)
    private int maxTeamSize = 5;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

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

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getShortName() {
        return shortName;
    }

    public void setShortName(String shortName) {
        this.shortName = shortName;
    }

    public String getTag() {
        return tag;
    }

    public void setTag(String tag) {
        this.tag = tag;
    }

    public String getGradientStart() {
        return gradientStart;
    }

    public void setGradientStart(String gradientStart) {
        this.gradientStart = gradientStart;
    }

    public String getGradientEnd() {
        return gradientEnd;
    }

    public void setGradientEnd(String gradientEnd) {
        this.gradientEnd = gradientEnd;
    }

    public String getIconUrl() {
        return iconUrl;
    }

    public void setIconUrl(String iconUrl) {
        this.iconUrl = iconUrl;
    }

    public List<String> getRanks() {
        return ranks;
    }

    public void setRanks(List<String> ranks) {
        this.ranks = ranks;
    }

    public List<String> getRoles() {
        return roles;
    }

    public void setRoles(List<String> roles) {
        this.roles = roles;
    }

    public int getMaxTeamSize() {
        return maxTeamSize;
    }

    public void setMaxTeamSize(int maxTeamSize) {
        this.maxTeamSize = maxTeamSize;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
