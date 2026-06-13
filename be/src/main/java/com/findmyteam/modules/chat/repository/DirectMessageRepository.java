package com.findmyteam.modules.chat.repository;

import com.findmyteam.modules.chat.entity.DirectMessage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface DirectMessageRepository extends JpaRepository<DirectMessage, UUID> {

    Page<DirectMessage> findByConversationIdOrderByCreatedAtDesc(UUID conversationId, Pageable pageable);

    Optional<DirectMessage> findBySenderIdAndClientMessageId(UUID senderId, String clientMessageId);
}
