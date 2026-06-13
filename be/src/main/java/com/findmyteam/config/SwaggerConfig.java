package com.findmyteam.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Find My Team API")
                .version("1.0.0")
                .description("""
                    # Find My Team Backend API

                    Nền tảng kết nối người chơi game - Tìm teammate, tạo team, giao lưu cộng đồng.

                    ## Authentication
                    Tất cả API cần xác thực (trừ public APIs) đều yêu cầu JWT token trong header:
                    ```
                    Authorization: Bearer <access_token>
                    ```

                    ## Flow
                    1. **Register** → Tạo tài khoản mới
                    2. **Login** → Nhận access_token và refresh_token
                    3. Sử dụng **access_token** cho các API cần xác thực
                    4. Khi **access_token** hết hạn → Dùng **refresh** để lấy token mới

                    ## Response Format
                    ```json
                    {
                        "success": true,
                        "data": { ... },
                        "message": "Optional message"
                    }
                    ```
                    """)
                .contact(new Contact()
                    .name("Find My Team Team")
                    .email("contact@findmyteam.com"))
                .license(new License()
                    .name("MIT License")))
            .servers(List.of(
                new Server().url("http://localhost:8080").description("Development Server"),
                new Server().url("https://api.findmyteam.com").description("Production Server")))
            .addSecurityItem(new SecurityRequirement().addList("Bearer Authentication"))
            .components(new Components()
                .addSecuritySchemes("Bearer Authentication", new SecurityScheme()
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")
                    .description("JWT access token. Đăng nhập để lấy token")));
    }
}
