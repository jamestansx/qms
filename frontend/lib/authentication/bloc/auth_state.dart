part of "auth_bloc.dart";

class AuthState extends Equatable {
  const AuthState._({
    this.status = AuthStatus.unknown,
    this.patient,
  });

  const AuthState.unknown() : this._();

  const AuthState.failure() : this._(status: AuthStatus.failure);

  const AuthState.authenticated(Patient patient)
      : this._(status: AuthStatus.authenticated, patient: patient);

  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final Patient? patient;

  @override
  List<Object?> get props => [status, patient];
}
