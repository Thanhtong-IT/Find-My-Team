package com.findmyteam.modules.user.repository;

import com.findmyteam.modules.user.entity.UserGameProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserGameProfileRepository extends JpaRepository<UserGameProfile, UUID> {

    List<UserGameProfile> findByUserId(UUID userId);

    Optional<UserGameProfile> findByUserIdAndGameId(UUID userId, UUID gameId);

    @Query("SELECT ugp FROM UserGameProfile ugp WHERE ugp.userId = :userId AND ugp.isPrimary = true")
    Optional<UserGameProfile> findPrimaryByUserId(UUID userId);

    void deleteByUserIdAndGameId(UUID userId, UUID gameId);
}
