import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../models/notification_models.dart';
import '../repositories/notification_repository.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final int initialTabIndex;

  const NotificationSettingsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<NotificationPreferenceModel> _preferences =
      NotificationCategoryMeta.normalizePreferences(const []);
  bool _loadingPrefs = true;
  bool _savingPrefs = false;
  String? _prefsError;

  List<NotificationItemModel> _inbox = const [];
  bool _loadingInbox = true;
  String? _inboxError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _loadingPrefs = false;
        _loadingInbox = false;
      });
      return;
    }
    await Future.wait([_loadPreferences(), _loadInbox()]);
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _loadingPrefs = true;
      _prefsError = null;
    });
    try {
      final prefs = await getIt<NotificationRepository>().getPreferences();
      if (!mounted) return;
      setState(() {
        _preferences = prefs;
        _loadingPrefs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _prefsError = e.toString().replaceAll('Exception: ', '');
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _loadInbox() async {
    setState(() {
      _loadingInbox = true;
      _inboxError = null;
    });
    try {
      final items = await getIt<NotificationRepository>().getNotifications();
      if (!mounted) return;
      setState(() {
        _inbox = items;
        _loadingInbox = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inboxError = e.toString().replaceAll('Exception: ', '');
        _loadingInbox = false;
      });
    }
  }

  Future<void> _toggleChannel(
    String category, {
    bool? webEnabled,
    bool? emailEnabled,
  }) async {
    if (_savingPrefs) return;
    final previous = List<NotificationPreferenceModel>.from(_preferences);
    final next = _preferences
        .map(
          (item) => item.category == category
              ? item.copyWith(webEnabled: webEnabled, emailEnabled: emailEnabled)
              : item,
        )
        .toList();

    setState(() {
      _preferences = next;
      _savingPrefs = true;
    });

    try {
      final saved = await getIt<NotificationRepository>().updatePreferences(next);
      if (!mounted) return;
      setState(() {
        _preferences = saved;
        _savingPrefs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _preferences = previous;
        _savingPrefs = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _markAllRead() async {
    try {
      await getIt<NotificationRepository>().markAllAsRead();
      if (!mounted) return;
      setState(() {
        _inbox = _inbox.map((item) => item.markReadLocally()).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đánh dấu tất cả thông báo là đã đọc.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _openNotification(NotificationItemModel item) async {
    if (!item.isRead) {
      setState(() {
        _inbox = _inbox
            .map((row) => row.id == item.id ? row.markReadLocally() : row)
            .toList();
      });
      try {
        await getIt<NotificationRepository>().markAsRead(item.id);
      } catch (_) {}
    }

    if (!mounted) return;
    final path = item.extractPath();
    if (path == null) return;

    final appMatch = RegExp(r'^/applications/(\d+)$').firstMatch(path);
    if (appMatch != null) {
      await context.push('/applications/${appMatch.group(1)}');
      return;
    }

    if (path.startsWith('/interview-schedules') || path.startsWith('/schedules')) {
      await context.push('/profile/interviews');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final unreadCount = _inbox.where((item) => !item.isRead).length;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _loadAll(),
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Thông Báo Tuyển Dụng'),
        bottom: authState is Authenticated
            ? TabBar(
                controller: _tabController,
                tabs: [
                  const Tab(
                    icon: Icon(Icons.tune_rounded, size: 18),
                    text: 'Cấu hình nhận',
                  ),
                  Tab(
                    icon: const Icon(Icons.inbox_outlined, size: 18),
                    text: unreadCount > 0 ? 'Hộp thư ($unreadCount)' : 'Hộp thư',
                  ),
                ],
              )
            : null,
      ),
      body: authState is! Authenticated
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 56, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    const Text(
                      'Đăng nhập để cấu hình thông báo',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bật hoặc tắt thông báo kết quả hồ sơ, bài đánh giá và lịch phỏng vấn theo kênh App/Web hoặc Gmail.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Đăng nhập ngay'),
                    ),
                  ],
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPreferencesTab(theme),
                _buildInboxTab(theme, unreadCount),
              ],
            ),
    ),
    );
  }

  Widget _buildPreferencesTab(ThemeData theme) {
    if (_loadingPrefs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_prefsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(_prefsError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPreferences,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final prefByCategory = {for (final p in _preferences) p.category: p};

    return RefreshIndicator(
      onRefresh: _loadPreferences,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _savingPrefs
                        ? 'Đang lưu thay đổi cấu hình thông báo...'
                        : 'Chọn loại thông báo bạn muốn nhận trên Ứng dụng/Web và qua Gmail. Thay đổi được lưu tự động.',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final meta in NotificationCategoryMeta.candidateCategories) ...[
            _CategoryPreferenceCard(
              meta: meta,
              preference: prefByCategory[meta.key] ??
                  NotificationPreferenceModel(
                    category: meta.key,
                    webEnabled: true,
                    emailEnabled: true,
                  ),
              disabled: _savingPrefs,
              onToggleWeb: (value) => _toggleChannel(meta.key, webEnabled: value),
              onToggleEmail: (value) => _toggleChannel(meta.key, emailEnabled: value),
            ),
            const SizedBox(height: 12),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Lưu ý: Dù tắt cả hai kênh, bạn vẫn luôn xem được lịch sử và kết quả chi tiết trong mục Ứng tuyển và Lịch phỏng vấn.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxTab(ThemeData theme, int unreadCount) {
    if (_loadingInbox) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_inboxError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(_inboxError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInbox,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_inbox.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadInbox,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.mark_email_read_outlined, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            const Text(
              'Chưa có thông báo nào',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Các cập nhật về hồ sơ, bài đánh giá và lịch phỏng vấn sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInbox,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$unreadCount thông báo chưa đọc',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                  ),
                  TextButton.icon(
                    onPressed: _markAllRead,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Đọc tất cả'),
                  ),
                ],
              ),
            ),
          for (final item in _inbox)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: item.isRead
                  ? null
                  : theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openNotification(item),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.isRead
                                ? Colors.transparent
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                              ),
                            ),
                            if (item.body != null && item.body!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.body!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (item.createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt!),
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryPreferenceCard extends StatelessWidget {
  final NotificationCategoryMeta meta;
  final NotificationPreferenceModel preference;
  final bool disabled;
  final ValueChanged<bool> onToggleWeb;
  final ValueChanged<bool> onToggleEmail;

  const _CategoryPreferenceCard({
    required this.meta,
    required this.preference,
    required this.disabled,
    required this.onToggleWeb,
    required this.onToggleEmail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(meta.icon, size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.label,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta.description,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              secondary: const Icon(Icons.notifications_none_rounded, size: 20),
              title: const Text('Thông báo trên Ứng dụng & Web', style: TextStyle(fontSize: 13)),
              value: preference.webEnabled,
              onChanged: disabled ? null : onToggleWeb,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              secondary: const Icon(Icons.mail_outline_rounded, size: 20),
              title: const Text('Thông báo qua Gmail', style: TextStyle(fontSize: 13)),
              value: preference.emailEnabled,
              onChanged: disabled ? null : onToggleEmail,
            ),
          ],
        ),
      ),
    );
  }
}
