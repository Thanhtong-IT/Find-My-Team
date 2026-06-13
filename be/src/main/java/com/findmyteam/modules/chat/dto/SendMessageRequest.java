package com.findmyteam.modules.chat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SendMessageRequest(
    @NotBlank(message = "Nội dung tin nhắn là bắt buộc")
    @Size(max = 4000, message = "Tin nhắn tối đa 4000 ký tự")
    String content,

    String imageUrl,

    String clientMessageId
) {}
