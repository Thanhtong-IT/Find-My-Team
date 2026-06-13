package com.findmyteam.config;

import com.findmyteam.websocket.FindMyTeamWebSocketHandler;
import com.findmyteam.websocket.WebSocketAuthInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.support.HttpSessionHandshakeInterceptor;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final FindMyTeamWebSocketHandler webSocketHandler;
    private final WebSocketAuthInterceptor authInterceptor;

    public WebSocketConfig(FindMyTeamWebSocketHandler webSocketHandler,
                          WebSocketAuthInterceptor authInterceptor) {
        this.webSocketHandler = webSocketHandler;
        this.authInterceptor = authInterceptor;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(webSocketHandler, "/ws")
            .addInterceptors(authInterceptor, new HttpSessionHandshakeInterceptor())
            .setAllowedOrigins("*");
    }
}
