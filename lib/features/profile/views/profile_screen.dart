import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injection.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../interviews/models/human_interview_model.dart';
import '../../interviews/repositories/interview_repository.dart';
import '../../mobile/models/mobile_dashboard_model.dart';
import '../../mobile/repositories/mobile_repository.dart';
import '../../tenant/bloc/tenant_bloc.dart';
import '../../tenant/bloc/tenant_state.dart';
import '../../tenant/utils/tenant_switch.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<HumanInterviewModel> _interviews = const [];

  MobileDashboardModel? _dashboard;
  MobileConfigModel? _mobileConfig;

  @override
  void initState() {
    super.initState();
    _loadProfileExtras();
  }

  Future<void> _loadProfileExtras() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      if (!mounted) return;
      setState(() {
        _interviews = const [];
      });
      return;
    }

    await Future.wait([
      _fetchInterviews(),
      _fetchMobileExtras(),
    ]);
  }

  Future<void> _fetchMobileExtras() async {
    try {
      final config = await getIt<MobileRepository>().getMobileConfig();
      if (mounted) setState(() => _mobileConfig = config);
    } catch (_) {}

    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      try {
        final dash = await getIt<MobileRepository>().getCandidateDashboard();
        if (mounted) setState(() => _dashboard = dash);
      } catch (_) {}
    }
  }

  Future<void> _fetchInterviews() async {
    try {
      final items = await getIt<InterviewRepository>().getMyInterviews();
      if (!mounted) return;
      setState(() {
        _interviews = items;
      });
    } catch (_) {}
  }

  Future<void> _openRouteAndRefresh(String path, {Object? extra}) async {
    await context.push(path, extra: extra);
    if (mounted) {
      await _loadProfileExtras();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenantState = context.watch<TenantBloc>().state;
    final tenant = tenantState is TenantSelected ? tenantState.tenant : null;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final now = DateTime.now();

    final upcomingInterviews = _interviews.where((i) => i.isUpcoming(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _loadProfileExtras();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tài Khoản & Cài Đặt'),
        ),
        body: RefreshIndicator(
          onRefresh: _loadProfileExtras,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                        child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: user.avatarUrl!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Icon(
                                    Icons.person_rounded,
                                    size: 32,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : Icon(
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
              if (user != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          theme,
                          label: 'Đang ứng tuyển',
                          value: '${_dashboard?.activeApplications ?? 0}',
                          icon: Icons.work_outline_rounded,
                          color: theme.colorScheme.primary,
                          onTap: () => context.go('/applications'),
                        ),
                        Container(height: 32, width: 1, color: theme.colorScheme.outlineVariant),
                        _buildStatColumn(
                          theme,
                          label: 'Lịch phỏng vấn',
                          value: '${_dashboard?.upcomingInterviewsCount ?? upcomingInterviews.length}',
                          icon: Icons.calendar_today_outlined,
                          color: Colors.green,
                          onTap: () => _openRouteAndRefresh('/profile/interviews'),
                        ),
                        Container(height: 32, width: 1, color: theme.colorScheme.outlineVariant),
                        _buildStatColumn(
                          theme,
                          label: 'Thông báo',
                          value: '${_dashboard?.unreadNotificationsCount ?? 0}',
                          icon: Icons.notifications_none_rounded,
                          color: Colors.orange,
                          onTap: () => _openRouteAndRefresh('/profile/notifications'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Active Tenant Info Section
              Text(
                'DOANH NGHIỆP ĐANG XEM',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: tenant?.logoUrl != null && tenant!.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: tenant.logoUrl!,
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                            errorWidget: (_, _, _) => Image.asset(
                              'assets/images/logo_smarthire_icon.png',
                              width: 34,
                              height: 34,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : Image.asset(
                          'assets/images/logo_smarthire_icon.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.contain,
                        ),
                  title: Text(
                    tenant?.name ?? 'Chưa chọn doanh nghiệp',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: tenant?.code != null
                      ? Text(
                          'Mã: ${tenant!.code.toUpperCase()}',
                          style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                        )
                      : null,
                  trailing: OutlinedButton.icon(
                    onPressed: () => switchTenantWorkspace(context),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Đổi', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  onTap: () => switchTenantWorkspace(context),
                ),
              ),
              const SizedBox(height: 20),

              // Interview Schedule Section
              Text(
                'LỊCH PHỎNG VẤN CỦA TÔI',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Colors.green, size: 22),
                  ),
                  title: const Text(
                    'Lịch phỏng vấn',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    user == null
                        ? 'Đăng nhập để xem lịch'
                        : (upcomingInterviews.isNotEmpty
                            ? 'Có ${upcomingInterviews.length} lịch hẹn sắp tới'
                            : 'Chưa có lịch hẹn sắp tới'),
                    style: TextStyle(fontSize: 12.5, color: theme.colorScheme.outline),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    if (user == null) {
                      context.push('/login');
                    } else {
                      _openRouteAndRefresh('/profile/interviews');
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

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
                      title: const Text('Cài đặt thông báo'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _openRouteAndRefresh('/profile/notifications'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('Phiên bản ứng dụng'),
                      trailing: Text(
                        _mobileConfig != null
                            ? 'v${_mobileConfig!.latestVersion}'
                            : '1.0.0 (SmartHire)',
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
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
