import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../tenant/bloc/tenant_bloc.dart';
import '../../tenant/bloc/tenant_event.dart';
import '../../tenant/bloc/tenant_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenantState = context.watch<TenantBloc>().state;
    final tenant = tenantState is TenantSelected ? tenantState.tenant : null;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài Khoản & Cài Đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      user != null ? Icons.person_rounded : Icons.person_outline_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null ? user.fullName : 'Khách ứng viên',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user != null ? user.email : 'Chưa đăng nhập tài khoản',
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  if (user == null)
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Đăng nhập', style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Active Tenant Info Section
          Text(
            'DOANH NGHIỆP ĐANG XEM',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: tenant?.logoUrl != null && tenant!.logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: tenant.logoUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) => const Icon(Icons.business_rounded, size: 32),
                      ),
                    )
                  : const Icon(Icons.business_rounded, size: 36),
              title: Text(
                tenant?.name ?? 'Chưa chọn công ty',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${tenant?.code ?? '...'}.smarthire.top',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
              trailing: OutlinedButton.icon(
                onPressed: () {
                  context.read<TenantBloc>().add(ClearTenantEvent());
                  context.go('/select-tenant');
                },
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text('Đổi', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App Settings & Actions
          Text(
            'HỆ THỐNG',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Thông báo tuyển dụng'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Phiên bản ứng dụng'),
                  trailing: Text(
                    '1.0.0 (SmartHire Mobile)',
                    style: TextStyle(color: theme.colorScheme.outline, fontSize: 13),
                  ),
                ),
                if (user != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                    title: Text(
                      'Đăng xuất',
                      style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      context.read<AuthBloc>().add(LogoutEvent());
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
