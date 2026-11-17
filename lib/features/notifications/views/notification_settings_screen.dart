import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/storage_service.dart';
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

  bool _isPushEnabled = true;
  bool _isSoundVibrateEnabled = true;

  List<NotificationPreferenceModel> _preferences =
      NotificationCategoryMeta.normalizePreferences(const []);
  bool _loadingPrefs = true;
  bool _savingPrefs = false;
  String? _prefsError;

  List<NotificationItemModel> _inbox = const [];
  bool _loadingInbox = true;
  String? _inboxError;
  String _inboxFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _isPushEnabled = getIt<StorageService>().isPushNotificationsEnabled();
    _isSoundVibrateEnabled = getIt<StorageService>().isSoundVibrateEnabled();
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

  Future<void> _togglePushMaster(bool value) async {
    setState(() {
      _isPushEnabled = value;
    });
    await getIt<StorageService>().setPushNotificationsEnabled(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Đã bật nhận thông báo đẩy trên điện thoại'
              : 'Đã tắt nhận thông báo đẩy trên điện thoại',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleSoundVibrate(bool value) async {
    setState(() {
      _isSoundVibrateEnabled = value;
    });
    await getIt<StorageService>().setSoundVibrateEnabled(value);
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          if (_savingPrefs)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2.5),
            ),

          // 1. CÀI ĐẶT THÔNG BÁO ĐẨY TRÊN ĐIỆN THOẠI (Mess/Zalo Style)
          _buildSectionHeader(theme, 'THÔNG BÁO TRÊN THIẾT BỊ'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _isPushEnabled,
                  onChanged: _togglePushMaster,
                  activeThumbColor: theme.colorScheme.primary,
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isPushEnabled
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isPushEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_outlined,
                      color: _isPushEnabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Nhận thông báo trên điện thoại',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    _isPushEnabled
                        ? 'Cho phép nhận thông báo đẩy khi có cập nhật mới'
                        : 'Đã tạm tắt tất cả thông báo gửi về điện thoại',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _isPushEnabled
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
                if (_isPushEnabled) ...[
                  Divider(height: 1, indent: 64, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  SwitchListTile.adaptive(
                    value: _isSoundVibrateEnabled,
                    onChanged: _toggleSoundVibrate,
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isSoundVibrateEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                    title: const Text('Âm thanh và rung', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Rung và chuông báo khi có thông báo tuyển dụng', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. CÁC LOẠI THÔNG BÁO ĐẨY VỀ MÁY
          _buildSectionHeader(theme, 'LOẠI THÔNG BÁO ĐẨY VỀ MÁY'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < NotificationCategoryMeta.candidateCategories.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 64, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  _buildCategoryPushTile(
                    theme: theme,
                    meta: NotificationCategoryMeta.candidateCategories[i],
                    pref: prefByCategory[NotificationCategoryMeta.candidateCategories[i].key] ??
                        NotificationPreferenceModel(
                          category: NotificationCategoryMeta.candidateCategories[i].key,
                          webEnabled: true,
                          emailEnabled: true,
                        ),
                    enabled: _isPushEnabled && !_savingPrefs,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. THÔNG BÁO DỰ PHÒNG QUA EMAIL
          _buildSectionHeader(theme, 'KÊNH THÔNG BÁO QUA GMAIL'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < NotificationCategoryMeta.candidateCategories.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 64, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  _buildCategoryEmailTile(
                    theme: theme,
                    meta: NotificationCategoryMeta.candidateCategories[i],
                    pref: prefByCategory[NotificationCategoryMeta.candidateCategories[i].key] ??
                        NotificationPreferenceModel(
                          category: NotificationCategoryMeta.candidateCategories[i].key,
                          webEnabled: true,
                          emailEnabled: true,
                        ),
                    enabled: !_savingPrefs,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Lưu ý: Dù tắt thông báo đẩy, bạn luôn có thể xem lại toàn bộ tin nhắn & kết quả trong tab "Hộp thư".',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.outline,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCategoryPushTile({
    required ThemeData theme,
    required NotificationCategoryMeta meta,
    required NotificationPreferenceModel pref,
    required bool enabled,
  }) {
    final isChecked = _isPushEnabled && pref.webEnabled;
    return SwitchListTile.adaptive(
      value: isChecked,
      onChanged: enabled
          ? (val) => _toggleChannel(meta.key, webEnabled: val)
          : null,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isChecked
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          meta.icon,
          color: isChecked ? theme.colorScheme.primary : theme.colorScheme.outline,
          size: 20,
        ),
      ),
      title: Text(
        meta.label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: enabled ? null : theme.colorScheme.outline,
        ),
      ),
      subtitle: Text(
        meta.description,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildCategoryEmailTile({
    required ThemeData theme,
    required NotificationCategoryMeta meta,
    required NotificationPreferenceModel pref,
    required bool enabled,
  }) {
    return SwitchListTile.adaptive(
      value: pref.emailEnabled,
      onChanged: enabled
          ? (val) => _toggleChannel(meta.key, emailEnabled: val)
          : null,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: pref.emailEnabled
              ? Colors.red.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.mail_outline_rounded,
          color: pref.emailEnabled ? Colors.red.shade700 : theme.colorScheme.outline,
          size: 20,
        ),
      ),
      title: Text(
        'Email ${meta.label.toLowerCase()}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        'Gửi thư thông báo về hòm thư Gmail của bạn',
        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
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

    final filteredInbox = _inbox.where((item) {
      if (_inboxFilter == 'UNREAD') return !item.isRead;
      final meta = NotificationDisplayMeta.fromItem(item);
      if (_inboxFilter == 'INTERVIEW') {
        return meta.categoryLabel == 'Lịch phỏng vấn' || meta.categoryLabel == 'Phỏng vấn AI';
      }
      if (_inboxFilter == 'APPLICATION') {
        return meta.categoryLabel == 'Hồ sơ ứng tuyển' || meta.categoryLabel == 'Bài đánh giá';
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadInbox,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả (${_inbox.length})', 'ALL', theme),
                const SizedBox(width: 8),
                _buildFilterChip('Chưa đọc ($unreadCount)', 'UNREAD', theme, highlight: unreadCount > 0),
                const SizedBox(width: 8),
                _buildFilterChip('Lịch phỏng vấn', 'INTERVIEW', theme),
                const SizedBox(width: 8),
                _buildFilterChip('Hồ sơ & Test', 'APPLICATION', theme),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Unread Banner / Mark all read action
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1E60EC),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Có $unreadCount thông báo mới',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E60EC),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _markAllRead,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Đọc tất cả', style: TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),

          if (filteredInbox.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.filter_list_off_rounded, size: 40, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(
                      'Không có thông báo nào trong mục này',
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final item in filteredInbox) ...[
              _buildNotificationCard(
                theme: theme,
                item: item,
                meta: NotificationDisplayMeta.fromItem(item),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme, {bool highlight = false}) {
    final isSelected = _inboxFilter == value;
    return InkWell(
      onTap: () => setState(() => _inboxFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E60EC)
              : (highlight ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1E60EC)
                : (highlight ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (highlight ? const Color(0xFF1E60EC) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required ThemeData theme,
    required NotificationItemModel item,
    required NotificationDisplayMeta meta,
  }) {
    final hasAction = item.extractPath() != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.isRead ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead
              ? const Color(0xFFE2E8F0)
              : meta.primaryColor.withValues(alpha: 0.35),
          width: item.isRead ? 1.0 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: item.isRead
                ? Colors.black.withValues(alpha: 0.01)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: item.isRead ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openNotification(item),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh màu nhấn bên trái cho tin chưa đọc
              Container(
                width: 4.5,
                color: item.isRead ? Colors.transparent : meta.primaryColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Squircle icon đại diện cho nhóm thông báo
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: meta.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: meta.primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(meta.icon, size: 21, color: meta.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dòng tag thể loại & thời gian
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: meta.backgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    meta.categoryLabel,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: meta.primaryColor,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTimeAgo(item.createdAt),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.outline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (!item.isRead) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF1E60EC),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                                color: item.isRead
                                    ? const Color(0xFF334155)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            if (item.body != null && item.body!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.body!.trim(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: item.isRead
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF475569),
                                  height: 1.45,
                                ),
                              ),
                            ],
                            if (hasAction) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Xem chi tiết',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: meta.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: meta.primaryColor,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua ${DateFormat("HH:mm").format(date)}';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

class NotificationDisplayMeta {
  final String categoryLabel;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;

  const NotificationDisplayMeta({
    required this.categoryLabel,
    required this.icon,
    required this.primaryColor,
    required this.backgroundColor,
  });

  static NotificationDisplayMeta fromItem(NotificationItemModel item) {
    final type = item.type.toUpperCase();
    final title = item.title.toLowerCase();

    if (type.contains('INTERVIEW') && !type.contains('AI') ||
        title.contains('phỏng vấn trực tiếp') ||
        title.contains('lịch phỏng vấn') ||
        title.contains('lịch hẹn')) {
      return const NotificationDisplayMeta(
        categoryLabel: 'Lịch phỏng vấn',
        icon: Icons.event_available_rounded,
        primaryColor: Color(0xFF059669),
        backgroundColor: Color(0xFFECFDF5),
      );
    }

    if (type.contains('AI') || title.contains('phỏng vấn ai') || title.contains('ai interview')) {
      return const NotificationDisplayMeta(
        categoryLabel: 'Phỏng vấn AI',
        icon: Icons.smart_toy_rounded,
        primaryColor: Color(0xFF7C3AED),
        backgroundColor: Color(0xFFF5F3FF),
      );
    }

    if (type.contains('ASSESSMENT') ||
        type.contains('TEST') ||
        title.contains('bài test') ||
        title.contains('bài đánh giá') ||
        title.contains('chấm điểm')) {
      return const NotificationDisplayMeta(
        categoryLabel: 'Bài đánh giá',
        icon: Icons.quiz_rounded,
        primaryColor: Color(0xFFD97706),
        backgroundColor: Color(0xFFFFFBEB),
      );
    }

    return const NotificationDisplayMeta(
      categoryLabel: 'Hồ sơ ứng tuyển',
      icon: Icons.description_rounded,
      primaryColor: Color(0xFF2563EB),
      backgroundColor: Color(0xFFEFF6FF),
    );
  }
}


