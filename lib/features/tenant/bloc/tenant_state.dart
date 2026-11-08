import 'package:equatable/equatable.dart';
import '../models/tenant_info.dart';

abstract class TenantState extends Equatable {
  const TenantState();

  @override
  List<Object?> get props => [];
}

class TenantInitial extends TenantState {}

class TenantLoading extends TenantState {}

class TenantSelected extends TenantState {
  final TenantInfo tenant;

  const TenantSelected(this.tenant);

  @override
  List<Object?> get props => [tenant];
}

class TenantError extends TenantState {
  final String message;

  const TenantError(this.message);

  @override
  List<Object?> get props => [message];
}
