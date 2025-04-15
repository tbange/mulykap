import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String? name;
  final String firstName;
  final String lastName;
  final String phone;
  final String userRole;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    this.name,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.userRole,
  });

  @override
  List<Object?> get props => [email, password, name, firstName, lastName, phone, userRole];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  const AuthResetPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}