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
import '../../interviews/views/widgets/interview_card.dart';
import '../../notifications/models/notification_models.dart';
import '../../notifications/repositories/notification_repository.dart';
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
  bool _loadingInterviews = false;
  String? _interviewsError;

  List<NotificationPreferenceModel> _preferences = const [];

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
        _preferences = const [];
        _loadingInterviews = false;
        _interviewsError = null;
      });
      return;
    }

    setState(() {
      _loadingInterviews = true;
      _interviewsError = null;
    });

    await Future.wait([
      _fetchInterviews(),
      _fetchPreferences(),
    ]);
  }

  Future<void> _fetchInterviews() async {
    try {
      final items = await getIt<InterviewRepository>().getMyInterviews();
      if (!mounted) return;
      setState(() {
        _interviews = items;
        _loadingInterviews = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _interviewsError = e.toString().replaceAll('Exception: ', '');
        _loadingInterviews = false;
      });
    }
  }

  Future<void> _fetchPreferences() async {
    try {
      final prefs = await getIt<NotificationRepository>().getPreferences();
      if (!mounted) return;
      setState(() {
        _preferences = prefs;
      });
    } catch (_) {
      // Keep subtitle clean if preferences could not be loaded in background.
    }
  }

  String _notificationSubtitle(bool isAuthenticated) {
    if (!isAuthenticated) {
      return 'Đăng nhập để cài đặt kênh nhận thông báo';
    }
    if (_preferences.isEmpty) {
      return 'Cấu hình nhận thông báo App/Web & Gmail';
    }
    final webCount = _preferences.where((p) => p.webEnabled).length;
    final emailCount = _preferences.where((p) => p.emailEnabled).length;
    final total = _preferences.length;
    return 'Đang bật $webCount/$total trên App/Web · $emailCount/$total qua Gmail';
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
    final pastCount = _interviews.length - upcomingInterviews.length;

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
                            errorWidget: (_, _, _) => Image.asset(
                              'assets/images/logo_smarthire_icon.png',
                              width: 38,
                              height: 38,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : Image.asset(
                          'assets/images/logo_smarthire_icon.png',
                          width: 38,
                          height: 38,
                          fit: BoxFit.contain,
                        ),
                  title: Text(
                    tenant?.name ?? 'Chưa chọn công ty',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${tenant?.code ?? '...'}.smarthire.top',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: () => switchTenantWorkspace(context),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Đổi', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Interview Schedule Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LỊCH PHỎNG VẤN CỦA TÔI',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (user != null)
                    TextButton(
                      onPressed: () => _openRouteAndRefresh('/profile/interviews'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Xem tất cả', style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (user == null)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.event_note_outlined, color: theme.colorScheme.primary),
                    title: const Text('Lịch & chi tiết phỏng vấn'),
                    subtitle: const Text('Đăng nhập để xem lịch hẹn, link phòng họp và xác nhận tham dự.'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/login'),
                  ),
                )
              else if (_loadingInterviews)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                  ),
                )
              else if (_interviewsError != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _interviewsError!,
                            style: TextStyle(fontSize: 13, color: theme.colorScheme.error),
                          ),
                        ),
                        TextButton(
                          onPressed: _fetchInterviews,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (upcomingInterviews.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, color: theme.colorScheme.outline),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Chưa có lịch phỏng vấn sắp tới',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Khi nhà tuyển dụng đặt lịch phỏng vấn trực tiếp, thời gian và chi tiết phòng họp sẽ hiển thị ngay tại đây.',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                        ),
                        if (pastCount > 0) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _openRouteAndRefresh('/profile/interviews'),
                            icon: const Icon(Icons.history_rounded, size: 16),
                            label: Text('Xem $pastCount lịch đã qua / đã hủy'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else ...[
                for (final interview in upcomingInterviews.take(3))
                  InterviewCard(
                    interview: interview,
                    compact: true,
                    onTap: () => _openRouteAndRefresh(
                      '/profile/interviews/${interview.id}',
                      extra: interview,
                    ),
                  ),
                if (upcomingInterviews.length > 3 || pastCount > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openRouteAndRefresh('/profile/interviews'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(
                        'Xem toàn bộ lịch phỏng vấn (${_interviews.length})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
              ],
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
                      title: const Text('Thông báo tuyển dụng'),
                      subtitle: Text(
                        _notificationSubtitle(user != null),
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _openRouteAndRefresh('/profile/notifications'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('Phiên bản ứng dụng'),
                      trailing: Text(
                        '1.0.0 (SmarthireAI)',
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
}
