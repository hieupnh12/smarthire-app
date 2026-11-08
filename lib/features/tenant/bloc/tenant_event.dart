import 'package:equatable/equatable.dart';

abstract class TenantEvent extends Equatable {
  const TenantEvent();

  @override
  List<Object?> get props => [];
}

class LoadCachedTenantEvent extends TenantEvent {}

class LookupTenantEvent extends TenantEvent {
  final String code;

  const LookupTenantEvent(this.code);

  @override
  List<Object?> get props => [code];
}

class ClearTenantEvent extends TenantEvent {}
