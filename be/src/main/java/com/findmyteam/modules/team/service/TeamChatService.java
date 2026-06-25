package com.findmyteam.modules.team.service;

import com.findmyteam.common.dto.PageResponse;
import com.findmyteam.common.event.EventPublisher;
import com.findmyteam.common.event.EventType;
import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.modules.team.dto.TeamMessageResponse;
import com.findmyteam.modules.team.entity.TeamMessage;
import com.findmyteam.modules.team.repository.TeamMessageRepository;
import com.findmyteam.modules.team.repository.TeamMemberRepository;
import com.findmyteam.modules.chat.dto.SendMessageRequest;
import com.findmyteam.modules.auth.entity.User;
import com.findmyteam.modules.auth.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class TeamChatService {

    private final TeamMessageRepository messageRepository;
    private final TeamMemberRepository memberRepository;
    private final EventPublisher eventPublisher;
    private final UserRepository userRepository;

    public TeamChatService(TeamMessageRepository messageRepository,
                          TeamMemberRepository memberRepository,
                          EventPublisher eventPublisher,
                          UserRepository userRepository) {
        this.messageRepository = messageRepository;
        this.memberRepository = memberRepository;
        this.eventPublisher = eventPublisher;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public PageResponse<TeamMessageResponse> getMessages(UUID teamId, Pageable pageable) {
        Page<TeamMessage> messages = messageRepository.findByTeamIdOrderByCreatedAtDesc(teamId, pageable);
        return PageResponse.from(messages.map(TeamMessageResponse::from));
    }

    @Transactional
    public TeamMessageResponse sendMessage(UUID senderId, UUID teamId, SendMessageRequest request) {
        if (!memberRepository.existsByTeamIdAndUserId(teamId, senderId)) {
            throw new BusinessException("Bạn không phải thành viên của team");
        }

        TeamMessage message = doSendMessage(senderId, teamId, request);

        // Get sender name for the event
        String senderName = userRepository.findById(senderId)
            .map(User::getDisplayName)
            .orElse("Unknown");

        eventPublisher.publish(EventType.TEAM_MESSAGE_CREATED, Map.of(
            "messageId", message.getId(),
            "teamId", teamId,
            "senderId", senderId,
            "senderName", senderName,
            "content", request.content(),
            "clientMessageId", request.clientMessageId() != null ? request.clientMessageId() : message.getId().toString()
        ));

        return TeamMessageResponse.from(message);
    }

    @Transactional
    protected TeamMessage doSendMessage(UUID senderId, UUID teamId, SendMessageRequest request) {
        if (request.clientMessageId() != null) {
            Optional<TeamMessage> existing = messageRepository
                .findBySenderIdAndClientMessageId(senderId, request.clientMessageId());
            if (existing.isPresent()) {
                return existing.get();
            }
        }

        TeamMessage message = new TeamMessage();
        message.setTeamId(teamId);
        message.setSenderId(senderId);
        message.setContent(request.content());
        message.setImageUrl(request.imageUrl());
        message.setClientMessageId(request.clientMessageId());
        return messageRepository.save(message);
    }
}
