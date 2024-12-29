part of "auth_bloc.dart";

sealed class AuthEvent {
  const AuthEvent();
}

final class LoginUser extends AuthEvent {
  final String username;
  final String password;

  const LoginUser({required this.username, required this.password});
}

final class SignupUser extends AuthEvent {
  final String username;
  final String password;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;

  const SignupUser({
    required this.username,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
  });
}

final class LogoutUser extends AuthEvent {}

final class StreamAuth extends AuthEvent {}
