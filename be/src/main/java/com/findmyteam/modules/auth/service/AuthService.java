package com.findmyteam.modules.auth.service;

import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.modules.auth.dto.AuthResponse;
import com.findmyteam.modules.auth.dto.LoginRequest;
import com.findmyteam.modules.auth.dto.RefreshTokenRequest;
import com.findmyteam.modules.auth.dto.RegisterRequest;
import com.findmyteam.modules.auth.entity.RefreshToken;
import com.findmyteam.modules.auth.entity.User;
import com.findmyteam.modules.auth.repository.RefreshTokenRepository;
import com.findmyteam.modules.auth.repository.UserRepository;
import com.findmyteam.security.JwtTokenProvider;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    public AuthService(UserRepository userRepository,
                      RefreshTokenRepository refreshTokenRepository,
                      PasswordEncoder passwordEncoder,
                      JwtTokenProvider jwtTokenProvider) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new BusinessException("Email đã được sử dụng");
        }
        if (userRepository.existsByUsername(request.username())) {
            throw new BusinessException("Username đã được sử dụng");
        }

        User user = new User();
        user.setEmail(request.email());
        user.setUsername(request.username());
        user.setFullName(request.fullName());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setDisplayName(request.fullName());
        user = userRepository.save(user);

        return generateAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.email())
            .orElseThrow(() -> new BusinessException("Email hoặc mật khẩu không đúng"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new BusinessException("Email hoặc mật khẩu không đúng");
        }

        return generateAuthResponse(user);
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        RefreshToken storedToken = refreshTokenRepository.findByToken(request.refreshToken())
            .orElseThrow(() -> new BusinessException("Refresh token không hợp lệ"));

        if (storedToken.getExpiresAt().isBefore(OffsetDateTime.now())) {
            refreshTokenRepository.delete(storedToken);
            throw new BusinessException("Refresh token đã hết hạn");
        }

        User user = userRepository.findById(storedToken.getUserId())
            .orElseThrow(() -> new BusinessException("Người dùng không tồn tại"));

        refreshTokenRepository.delete(storedToken);

        return generateAuthResponse(user);
    }

    @Transactional
    public void logout(UUID userId) {
        refreshTokenRepository.deleteByUserId(userId);
    }

    private AuthResponse generateAuthResponse(User user) {
        String accessToken = jwtTokenProvider.generateAccessToken(
            user.getId(), user.getEmail(), user.getUsername());

        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getId());

        RefreshToken tokenEntity = new RefreshToken();
        tokenEntity.setUserId(user.getId());
        tokenEntity.setToken(refreshToken);
        tokenEntity.setExpiresAt(jwtTokenProvider.getRefreshTokenExpirationDate());
        refreshTokenRepository.save(tokenEntity);

        OffsetDateTime now = OffsetDateTime.now();

        return new AuthResponse(
            user.getId(),
            user.getEmail(),
            user.getUsername(),
            user.getFullName(),
            user.getDisplayName(),
            user.getAvatarUrl(),
            accessToken,
            refreshToken,
            now.plusHours(1),
            jwtTokenProvider.getRefreshTokenExpirationDate()
        );
    }
}
