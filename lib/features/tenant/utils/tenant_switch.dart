import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/tenant_bloc.dart';
import '../bloc/tenant_event.dart';

/// Clears the active tenant and session state before navigating to tenant selection.
void switchTenantWorkspace(BuildContext context) {
  context.read<TenantBloc>().add(ClearTenantEvent());
  context.read<AuthBloc>().add(SessionExpiredEvent());
  context.go('/select-tenant?change=true');
}

