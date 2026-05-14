package com.college.notice.auth.service;

import com.college.notice.auth.dto.AuthResponse;
import com.college.notice.auth.dto.LoginRequest;
import com.college.notice.auth.dto.RegisterRequest;
import com.college.notice.auth.dto.UpdateProfileRequest;
import com.college.notice.auth.dto.UserResponse;
import com.college.notice.auth.entity.User;
import com.college.notice.auth.exception.InvalidCredentialsException;
import com.college.notice.auth.repository.UserRepository;
import com.college.notice.auth.security.JwtService;
import com.college.notice.shared.constants.Role;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Transactional(readOnly = true)
    public UserResponse getProfile() {
        return toUserResponse(resolveCurrentUser());
    }

    @Transactional
    public UserResponse updateProfile(UpdateProfileRequest request) {
        User user = resolveCurrentUser();
        user.setName(request.getName());
        user.setDepartment(request.getDepartment());
        user.setYear(request.getYear());
        return toUserResponse(userRepository.save(user));
    }

    private User resolveCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new RuntimeException("Unauthenticated request");
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof User userPrincipal) {
            return userRepository.findByEmail(userPrincipal.getEmail())
                    .orElseThrow(() -> new RuntimeException("User not found"));
        }
        throw new RuntimeException("Unauthenticated request");
    }

    private UserResponse toUserResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .role(user.getRole())
                .department(user.getDepartment())
                .year(user.getYear())
                .build();
    }

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("Email is already registered");
        }

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(Role.STUDENT)
                .department(request.getDepartment())
                .year(request.getYear())
                .build();

        User savedUser = userRepository.save(user);
        return AuthResponse.builder()
                .accessToken(jwtService.generateAccessToken(savedUser))
                .refreshToken(jwtService.generateRefreshToken(savedUser))
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new InvalidCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new InvalidCredentialsException("Invalid email or password");
        }

        return AuthResponse.builder()
                .accessToken(jwtService.generateAccessToken(user))
                .refreshToken(jwtService.generateRefreshToken(user))
                .build();
    }
}
