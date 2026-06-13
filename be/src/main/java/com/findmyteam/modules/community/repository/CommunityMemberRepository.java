package com.findmyteam.modules.community.repository;

import com.findmyteam.modules.community.entity.CommunityMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CommunityMemberRepository extends JpaRepository<CommunityMember, UUID> {

    List<CommunityMember> findByCommunityId(UUID communityId);

    List<CommunityMember> findByUserId(UUID userId);

    Optional<CommunityMember> findByCommunityIdAndUserId(UUID communityId, UUID userId);

    boolean existsByCommunityIdAndUserId(UUID communityId, UUID userId);

    void deleteByCommunityIdAndUserId(UUID communityId, UUID userId);
}
