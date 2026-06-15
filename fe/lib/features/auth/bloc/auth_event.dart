import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final String? fullName;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.username,
    this.fullName,
  });

  @override
  List<Object?> get props => [email, password, username, fullName];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
