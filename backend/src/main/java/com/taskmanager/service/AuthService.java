package com.taskmanager.service;

import com.taskmanager.dto.AuthResponse;
import com.taskmanager.dto.LoginRequest;
import com.taskmanager.dto.RegisterRequest;
import com.taskmanager.entity.User;
import com.taskmanager.exception.BadRequestException;
import com.taskmanager.repository.UserRepository;
import com.taskmanager.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

	private final UserRepository userRepository;
	private final PasswordEncoder passwordEncoder;
	private final JwtService jwtService;
	private final AuthenticationManager authenticationManager;

	public AuthResponse register(RegisterRequest request) {
		if (userRepository.existsByEmail(request.getEmail())) {
			throw new BadRequestException("Cet email est deja utilise");
		}

		User user = User.builder()
				.email(request.getEmail().trim().toLowerCase())
				.password(passwordEncoder.encode(request.getPassword()))
				.fullName(request.getFullName().trim())
				.build();

		userRepository.save(user);
		String token = jwtService.generateToken(user.getEmail());
		return AuthResponse.builder()
				.token(token)
				.email(user.getEmail())
				.fullName(user.getFullName())
				.build();
	}

	public AuthResponse login(LoginRequest request) {
		authenticationManager.authenticate(
				new UsernamePasswordAuthenticationToken(
						request.getEmail().trim().toLowerCase(),
						request.getPassword()));

		User user = userRepository.findByEmail(request.getEmail().trim().toLowerCase())
				.orElseThrow(() -> new BadRequestException("Utilisateur introuvable"));

		String token = jwtService.generateToken(user.getEmail());
		return AuthResponse.builder()
				.token(token)
				.email(user.getEmail())
				.fullName(user.getFullName())
				.build();
	}
}
