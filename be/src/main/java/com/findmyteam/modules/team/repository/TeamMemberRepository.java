package com.findmyteam.modules.team.repository;

import com.findmyteam.modules.team.entity.TeamMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TeamMemberRepository extends JpaRepository<TeamMember, UUID> {

    @Query("SELECT tm FROM TeamMember tm JOIN FETCH tm.user WHERE tm.teamId = :teamId")
    List<TeamMember> findByTeamId(UUID teamId);

    @Query("SELECT tm FROM TeamMember tm JOIN FETCH tm.user WHERE tm.teamId = :teamId AND tm.status = 'ACTIVE'")
    List<TeamMember> findActiveMembersByTeamId(UUID teamId);

    Optional<TeamMember> findByTeamIdAndUserId(UUID teamId, UUID userId);

    @Query("SELECT tm FROM TeamMember tm WHERE tm.teamId = :teamId AND tm.userId = :userId AND tm.status = 'ACTIVE'")
    Optional<TeamMember> findActiveMemberByTeamIdAndUserId(UUID teamId, UUID userId);

    @Query("SELECT tm FROM TeamMember tm WHERE tm.userId = :userId")
    List<TeamMember> findByUserId(UUID userId);

    @Query("SELECT COUNT(tm) FROM TeamMember tm WHERE tm.teamId = :teamId")
    int countByTeamId(UUID teamId);

    @Query("SELECT COUNT(tm) FROM TeamMember tm WHERE tm.teamId = :teamId AND tm.status = 'ACTIVE'")
    int countActiveMembersByTeamId(UUID teamId);

    boolean existsByTeamIdAndUserId(UUID teamId, UUID userId);

    void deleteByTeamIdAndUserId(UUID teamId, UUID userId);
}
