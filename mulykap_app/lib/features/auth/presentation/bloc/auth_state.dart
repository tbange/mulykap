import 'package:equatable/equatable.dart';
import 'package:mulykap_app/features/auth/domain/models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, submitting }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel user;
  final String? error;

  const AuthState._({
    this.status = AuthStatus.initial,
    this.user = UserModel.empty,
    this.error,
  });

  const AuthState.initial() : this._();

  const AuthState.authenticated(UserModel user)
      : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated([String? error])
      : this._(
          status: AuthStatus.unauthenticated,
          error: error,
        );
        
  const AuthState.submitting()
      : this._(
          status: AuthStatus.submitting,
        );

  bool get isInitial => status == AuthStatus.initial;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isSubmitting => status == AuthStatus.submitting;

  @override
  List<Object?> get props => [status, user, error];
} 