import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.initial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthResetPasswordRequested>(_onAuthResetPasswordRequested);

    // S'abonner aux changements d'état d'authentification
    _authSubscription = _authRepository.authStateChanges.listen((authState) {
      if (authState.event == supabase.AuthChangeEvent.signedIn ||
          authState.event == supabase.AuthChangeEvent.userUpdated) {
        add(const AuthCheckRequested());
      } else if (authState.event == supabase.AuthChangeEvent.signedOut) {
        emit(const AuthState.unauthenticated());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user.isEmpty) {
        emit(const AuthState.unauthenticated());
      } else {
        emit(AuthState.authenticated(user));
      }
    } catch (e) {
      emit(AuthState.unauthenticated(e.toString()));
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Émettre l'état de soumission
    emit(const AuthState.submitting());
    
    print('Début de la tentative d\'inscription pour ${event.email}');
    print('Rôle sélectionné: ${event.userRole}');
    
    try {
      await _authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        userRole: event.userRole,
      );
      
      print('Inscription réussie pour ${event.email}');
      
      // Récupérer l'utilisateur actuel après l'inscription
      final user = await _authRepository.getCurrentUser();
      
      // Émettre directement l'état authentifié
      emit(AuthState.authenticated(user));
      
      print('État authentifié émis pour ${user.email}');
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      final errorMessage = 'Erreur d\'inscription: ${e.toString()}';
      emit(AuthState.unauthenticated(errorMessage));
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Émettre l'état de soumission
    emit(const AuthState.submitting());
    
    try {
      print('Début de la tentative de connexion pour ${event.email}');
      await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      
      // Récupérer l'utilisateur actuel après la connexion
      final user = await _authRepository.getCurrentUser();
      
      // Émettre directement l'état authentifié
      emit(AuthState.authenticated(user));
      
      print('État authentifié émis pour ${user.email}');
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      final errorMessage = 'Erreur de connexion: ${e.toString()}';
      emit(AuthState.unauthenticated(errorMessage));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.unauthenticated(e.toString()));
    }
  }

  Future<void> _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.resetPassword(email: event.email);
    } catch (e) {
      emit(AuthState.unauthenticated(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
} 