package com.findmyteam.modules.community.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateChannelRequest(
    @NotBlank(message = "Tên channel là bắt buộc")
    @Size(max = 100, message = "Tên channel tối đa 100 ký tự")
    String name,

    @Size(max = 10, message = "Type không hợp lệ")
    String type
) {}
