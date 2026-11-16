import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/views/widgets/unauthenticated_prompt_view.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';
import '../utils/application_labels.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<ApplicationModel> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'ALL'; // ALL, ACTIVE, FINISHED

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await getIt<ApplicationRepository>().getMyApplications();
      if (!mounted) return;
      setState(() {
        _applications = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openApplicationDetail(ApplicationModel app) async {
    await context.push('/applications/${app.id}', extra: app);
    if (mounted) {
      await _fetchApplications();
    }
  }

  List<ApplicationModel> get _filteredApplications {
    if (_filter == 'ACTIVE') {
      return _applications.where((app) {
        final st = app.status.toUpperCase();
        return st != 'REJECTED' && st != 'FAILED' && st != 'WITHDRAWN' && st != 'HIRED';
      }).toList();
    }
    if (_filter == 'FINISHED') {
      return _applications.where((app) {
        final st = app.status.toUpperCase();
        return st == 'REJECTED' || st == 'FAILED' || st == 'WITHDRAWN' || st == 'HIRED';
      }).toList();
    }
    return _applications;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _fetchApplications();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hồ Sơ Đã Ứng Tuyển'),
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isLoading ? null : _fetchApplications,
            ),
          ],
        ),
        body: authState is! Authenticated
            ? const UnauthenticatedPromptView(
                icon: Icons.lock_person_outlined,
                title: 'Đăng nhập để theo dõi hồ sơ',
                description:
                    'Xem trạng thái duyệt CV, điểm số đánh giá các vòng và lịch phỏng vấn.',
                buttonLabel: 'Đăng nhập ngay',
              )
            : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView(theme)
                    : Column(
                        children: [
                          // Filter bar
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                            child: Row(
                              children: [
                                _buildFilterTab('ALL', 'Tất cả (${_applications.length})', theme),
                                const SizedBox(width: 8),
                                _buildFilterTab(
                                  'ACTIVE',
                                  'Đang xử lý (${_applications.where((a) => a.status != 'REJECTED' && a.status != 'FAILED' && a.status != 'WITHDRAWN' && a.status != 'HIRED').length})',
                                  theme,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterTab(
                                  'FINISHED',
                                  'Đã xong (${_applications.where((a) => a.status == 'REJECTED' || a.status == 'FAILED' || a.status == 'WITHDRAWN' || a.status == 'HIRED').length})',
                                  theme,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 4),

                          Expanded(
                            child: _filteredApplications.isEmpty
                                ? _buildEmptyView(theme)
                                : RefreshIndicator(
                                    onRefresh: _fetchApplications,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                                      itemCount: _filteredApplications.length,
                                      itemBuilder: (context, index) {
                                        final app = _filteredApplications[index];
                                        return _buildApplicationCard(app, theme);
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildFilterTab(String key, String label, ThemeData theme) {
    final isSelected = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text(
              'Chưa có hồ sơ nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bạn chưa nộp hồ sơ vào vị trí công việc nào.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/jobs'),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Xem danh sách việc làm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'Đã có lỗi xảy ra', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchApplications,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(ApplicationModel app, ThemeData theme) {
    final statusColor = ApplicationLabels.statusColor(app.status, theme);
    final statusText = ApplicationLabels.statusLabel(app.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openApplicationDetail(app),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Role Icon + Job Title & Status Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.business_center_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.jobTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (app.jobDepartment != null && app.jobDepartment!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              app.jobDepartment!.trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Middle: Compact Info Chips
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxChipWidth = constraints.maxWidth;
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // Stage chip
                        if (app.stageName != null && app.stageName!.isNotEmpty)
                          _buildChip(
                            icon: Icons.flag_outlined,
                            label: app.stageName!,
                            color: const Color(0xFF475569),
                            bgColor: const Color(0xFFF1F5F9),
                            maxWidth: maxChipWidth,
                          ),

                        // AI Match chip
                        if (app.matchingScore != null)
                          _buildChip(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Match ${(app.matchingScore! * 100).toStringAsFixed(0)}%',
                            color: const Color(0xFF047857),
                            bgColor: const Color(0xFFECFDF5),
                            maxWidth: maxChipWidth,
                          ),

                        // Location chip
                        if (app.jobLocation != null && app.jobLocation!.trim().isNotEmpty)
                          _buildChip(
                            icon: Icons.location_on_outlined,
                            label: app.jobLocation!.trim(),
                            color: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
                            maxWidth: maxChipWidth,
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Footer: Date & Arrow
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          app.createdAt != null
                              ? 'Nộp ngày ${DateFormat('dd/MM/yyyy').format(app.createdAt!)}'
                              : 'Mã hồ sơ: #${app.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem chi tiết',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E60EC),
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Color(0xFF1E60EC),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    double? maxWidth,
  }) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
