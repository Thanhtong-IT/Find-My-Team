package com.findmyteam.modules.community.repository;

import com.findmyteam.modules.community.entity.Community;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CommunityRepository extends JpaRepository<Community, UUID> {

    Page<Community> findByIsPublicTrue(Pageable pageable);

    Page<Community> findByGameIdAndIsPublicTrue(UUID gameId, Pageable pageable);

    List<Community> findByOwnerId(UUID ownerId);
}
