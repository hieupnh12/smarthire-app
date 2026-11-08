import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<GoogleLoginEvent>(_onGoogleLogin);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    final user = await _repository.checkCurrentUser();
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onGoogleLogin(GoogleLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.loginWithGoogle();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _repository.logout();
    emit(Unauthenticated());
  }
}
