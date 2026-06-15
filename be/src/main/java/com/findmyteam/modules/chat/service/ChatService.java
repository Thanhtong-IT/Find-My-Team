package com.findmyteam.modules.chat.service;

import com.findmyteam.common.dto.PageResponse;
import com.findmyteam.common.event.EventPublisher;
import com.findmyteam.common.event.EventType;
import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.common.exception.ResourceNotFoundException;
import com.findmyteam.modules.chat.dto.MessageResponse;
import com.findmyteam.modules.chat.dto.SendMessageRequest;
import com.findmyteam.modules.chat.entity.Message;
import com.findmyteam.modules.chat.repository.MessageRepository;
import com.findmyteam.modules.community.entity.Channel;
import com.findmyteam.modules.community.entity.CommunityMember;
import com.findmyteam.modules.community.repository.ChannelRepository;
import com.findmyteam.modules.community.repository.CommunityMemberRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class ChatService {

    private final MessageRepository messageRepository;
    private final ChannelRepository channelRepository;
    private final CommunityMemberRepository memberRepository;
    private final EventPublisher eventPublisher;

    public ChatService(MessageRepository messageRepository,
                      ChannelRepository channelRepository,
                      CommunityMemberRepository memberRepository,
                      EventPublisher eventPublisher) {
        this.messageRepository = messageRepository;
        this.channelRepository = channelRepository;
        this.memberRepository = memberRepository;
        this.eventPublisher = eventPublisher;
    }

    @Transactional(readOnly = true)
    public PageResponse<MessageResponse> getMessages(UUID communityId, UUID channelId, Pageable pageable) {
        Channel channel = channelRepository.findById(channelId)
            .orElseThrow(() -> new ResourceNotFoundException("Channel", "id", channelId));

        if (!channel.getCommunityId().equals(communityId)) {
            throw new BusinessException("Channel không thuộc community này");
        }

        Page<Message> messages = messageRepository.findByChannelIdOrderByCreatedAtDesc(channelId, pageable);
        return PageResponse.from(messages.map(MessageResponse::from));
    }

    @Transactional
    public MessageResponse sendMessage(UUID userId, UUID communityId, UUID channelId, SendMessageRequest request) {
        Channel channel = channelRepository.findById(channelId)
            .orElseThrow(() -> new ResourceNotFoundException("Channel", "id", channelId));

        if (!channel.getCommunityId().equals(communityId)) {
            throw new BusinessException("Channel không thuộc community này");
        }

        CommunityMember member = memberRepository.findByCommunityIdAndUserId(communityId, userId)
            .orElseThrow(() -> new BusinessException("Bạn không phải thành viên community"));

        Message message = doSendMessage(userId, channelId, request);

        eventPublisher.publish(EventType.MESSAGE_CREATED, Map.of(
            "messageId", message.getId(),
            "channelId", channelId,
            "communityId", communityId,
            "senderId", userId,
            "senderName", member.getUser() != null ? member.getUser().getDisplayName() : null
        ));

        return MessageResponse.from(message);
    }

    @Transactional
    protected Message doSendMessage(UUID senderId, UUID channelId, SendMessageRequest request) {
        if (request.clientMessageId() != null) {
            Optional<Message> existing = messageRepository
                .findBySenderIdAndClientMessageId(senderId, request.clientMessageId());
            if (existing.isPresent()) {
                return existing.get();
            }
        }

        Message message = new Message();
        message.setChannelId(channelId);
        message.setSenderId(senderId);
        message.setContent(request.content());
        message.setImageUrl(request.imageUrl());
        message.setClientMessageId(request.clientMessageId());
        return messageRepository.save(message);
    }
}
