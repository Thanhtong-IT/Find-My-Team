package com.findmyteam.modules.chat.repository;

import com.findmyteam.modules.chat.entity.ConversationMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ConversationMemberRepository extends JpaRepository<ConversationMember, UUID> {

    List<ConversationMember> findByConversationId(UUID conversationId);

    List<ConversationMember> findByUserId(UUID userId);

    Optional<ConversationMember> findByConversationIdAndUserId(UUID conversationId, UUID userId);

    boolean existsByConversationIdAndUserId(UUID conversationId, UUID userId);

    @Query("""
        SELECT cm.unreadCount FROM ConversationMember cm
        WHERE cm.conversationId = :conversationId AND cm.userId = :userId
        """)
    int getUnreadCount(UUID conversationId, UUID userId);

    @Query("""
        SELECT SUM(cm.unreadCount) FROM ConversationMember cm
        WHERE cm.userId = :userId
        """)
    long getTotalUnreadCount(UUID userId);
}
