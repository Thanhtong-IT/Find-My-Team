package com.findmyteam.modules.chat.repository;

import com.findmyteam.modules.chat.entity.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface MessageRepository extends JpaRepository<Message, UUID> {

    Page<Message> findByChannelIdOrderByCreatedAtDesc(UUID channelId, Pageable pageable);

    Optional<Message> findBySenderIdAndClientMessageId(UUID senderId, String clientMessageId);

    @Modifying
    @Query(value = "UPDATE messages SET updated_at = NOW() WHERE channel_id = :channelId", nativeQuery = true)
    void touchChannel(UUID channelId);
}
