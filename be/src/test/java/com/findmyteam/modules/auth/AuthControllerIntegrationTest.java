package com.findmyteam.modules.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.findmyteam.modules.auth.dto.LoginRequest;
import com.findmyteam.modules.auth.dto.RegisterRequest;
import com.findmyteam.modules.auth.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class AuthControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("POST /api/auth/register - Success")
    void register_Success() throws Exception {
        RegisterRequest request = new RegisterRequest(
            "test@example.com",
            "testuser",
            "Test User",
            "password123"
        );

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.email").value("test@example.com"))
            .andExpect(jsonPath("$.data.username").value("testuser"))
            .andExpect(jsonPath("$.data.accessToken").exists())
            .andExpect(jsonPath("$.data.refreshToken").exists());
    }

    @Test
    @DisplayName("POST /api/auth/register - Email already exists")
    void register_EmailExists() throws Exception {
        RegisterRequest request1 = new RegisterRequest(
            "test@example.com",
            "testuser1",
            "Test User 1",
            "password123"
        );

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request1)))
            .andExpect(status().isCreated());

        RegisterRequest request2 = new RegisterRequest(
            "test@example.com",
            "testuser2",
            "Test User 2",
            "password123"
        );

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request2)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("Email đã được sử dụng"));
    }

    @Test
    @DisplayName("POST /api/auth/register - Invalid request")
    void register_InvalidRequest() throws Exception {
        RegisterRequest request = new RegisterRequest(
            "invalid-email",
            "ab",
            "",
            "123"
        );

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @DisplayName("POST /api/auth/login - Success")
    void login_Success() throws Exception {
        RegisterRequest registerRequest = new RegisterRequest(
            "test@example.com",
            "testuser",
            "Test User",
            "password123"
        );

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)))
            .andExpect(status().isCreated());

        LoginRequest loginRequest = new LoginRequest(
            "test@example.com",
            "password123"
        );

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.accessToken").exists());
    }

    @Test
    @DisplayName("POST /api/auth/login - Wrong password")
    void login_WrongPassword() throws Exception {
        RegisterRequest registerRequest = new RegisterRequest(
            "test@example.com",
            "testuser",
            "Test User",
            "password123"
        );

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)))
            .andExpect(status().isCreated());

        LoginRequest loginRequest = new LoginRequest(
            "test@example.com",
            "wrongpassword"
        );

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("Email hoặc mật khẩu không đúng"));
    }

    @Test
    @DisplayName("POST /api/auth/login - User not found")
    void login_UserNotFound() throws Exception {
        LoginRequest loginRequest = new LoginRequest(
            "nonexistent@example.com",
            "password123"
        );

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("Email hoặc mật khẩu không đúng"));
    }
}
