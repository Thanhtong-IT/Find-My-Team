package com.findmyteam.modules.community.dto;

import com.findmyteam.modules.community.entity.Channel;
import java.time.OffsetDateTime;
import java.util.UUID;

public record ChannelResponse(
    UUID id,
    UUID communityId,
    String name,
    String type,
    int position,
    OffsetDateTime createdAt
) {
    public static ChannelResponse from(Channel channel) {
        return new ChannelResponse(
            channel.getId(),
            channel.getCommunityId(),
            channel.getName(),
            channel.getType(),
            channel.getPosition(),
            channel.getCreatedAt()
        );
    }
}
