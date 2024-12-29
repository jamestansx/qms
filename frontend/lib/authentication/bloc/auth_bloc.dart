import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qms/authentication/services/authentication.dart';
import 'package:qms/patient/model/patient.dart';
import 'package:shared_preferences/shared_preferences.dart';

part "auth_state.dart";
part "auth_event.dart";

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepo authRepo,
  })  : _authRepo = authRepo,
        super(const AuthState.unknown()) {
    on<StreamAuth>(_onStreamAuthRequested);
    on<LoginUser>(_onUserLogin);
    on<LogoutUser>(_onUserLogout);
    on<SignupUser>(_onUserSignup);
  }

  final AuthRepo _authRepo;

  Future<void> _onStreamAuthRequested(
    StreamAuth event,
    Emitter<AuthState> emit,
  ) async {
    return emit.onEach(
      _authRepo.status,
      onData: (status) async {
        switch (status) {
          case AuthStatus.unknown:
            return emit(const AuthState.unknown());
          case AuthStatus.authenticated:
            final prefs = SharedPreferencesAsync();
            final user = await prefs.getString("user");
            return emit(
              user != null
                  ? AuthState.authenticated(Patient.fromJson(jsonDecode(user)))
                  : AuthState.unauthenticated(),
            );
          case AuthStatus.unauthenticated:
            return emit(const AuthState.unauthenticated());
          case AuthStatus.failure:
            return emit(const AuthState.failure());
        }
      },
    );
  }

  Future<void> _onUserLogin(
    LoginUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.unknown());
    final Patient user = await _authRepo.login(
      username: event.username,
      password: event.password,
    );
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setString("user", jsonEncode(user.toJson()));
  }

  Future<void> _onUserSignup(
    SignupUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.unknown());
    final Patient user = await _authRepo.register(
      username: event.username,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
      dateOfBirth: event.dateOfBirth,
    );
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setString("user", jsonEncode(user.toJson()));
  }

  Future<void> _onUserLogout(
    LogoutUser event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepo.logout();
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.remove("user");
  }
}
