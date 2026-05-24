import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../shared/services/session_manager.dart';

// --- Events ---
abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested(this.email, this.password);
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;
  AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}

class AuthLogoutRequested extends AuthEvent {}

// --- States ---
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final Map<String, dynamic> user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

// --- Bloc ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await SessionManager.init();
    if (SessionManager.isAuthenticated) {
      emit(Authenticated(SessionManager.user!));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(event.email, event.password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onAuthRegisterRequested(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(
        event.name,
        event.email,
        event.password,
        event.role,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onAuthLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}
