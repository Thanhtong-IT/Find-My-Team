package com.findmyteam.modules.community.repository;

import com.findmyteam.modules.community.entity.Channel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ChannelRepository extends JpaRepository<Channel, UUID> {

    List<Channel> findByCommunityIdOrderByPositionAsc(UUID communityId);

    Optional<Channel> findByCommunityIdAndName(UUID communityId, String name);

    @Query("SELECT COALESCE(MAX(c.position), 0) + 1 FROM Channel c WHERE c.communityId = :communityId")
    int getNextPosition(UUID communityId);
}
