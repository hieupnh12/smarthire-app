import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class GoogleLoginEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}

class SessionExpiredEvent extends AuthEvent {}
