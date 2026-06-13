package com.findmyteam.modules.chat.repository;

import com.findmyteam.modules.chat.entity.Conversation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, UUID> {

    @Query("""
        SELECT c FROM Conversation c
        JOIN ConversationMember cm ON cm.conversationId = c.id
        WHERE cm.userId = :userId
        ORDER BY c.lastMessageAt DESC NULLS LAST
        """)
    Page<Conversation> findByUserId(UUID userId, Pageable pageable);
}
