package com.findmyteam.modules.match.repository;

import com.findmyteam.modules.match.entity.Swipe;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SwipeRepository extends JpaRepository<Swipe, UUID> {

    Optional<Swipe> findBySwiperIdAndTargetIdAndGameId(UUID swiperId, UUID targetId, UUID gameId);

    boolean existsBySwiperIdAndTargetIdAndGameId(UUID swiperId, UUID targetId, UUID gameId);

    @Query("""
        SELECT CASE WHEN COUNT(s) > 0 THEN true ELSE false END
        FROM Swipe s
        WHERE s.swiperId = :swiperId AND s.targetId = :targetId AND s.direction = 'like'
        """)
    boolean hasLiked(UUID swiperId, UUID targetId);
}
