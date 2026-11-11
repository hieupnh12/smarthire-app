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

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
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
        ),
        body: authState is! Authenticated
            ? const UnauthenticatedPromptView(
                icon: Icons.lock_person_outlined,
                title: 'Đăng nhập để theo dõi hồ sơ',
                description:
                    'Xem trạng thái phê duyệt CV, lịch sử đánh giá các vòng và lịch phỏng vấn của bạn.',
                buttonLabel: 'Đăng nhập tài khoản',
              )
            : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView(theme)
                    : _applications.isEmpty
                        ? _buildEmptyView(theme)
                        : RefreshIndicator(
                            onRefresh: _fetchApplications,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _applications.length,
                              itemBuilder: (context, index) {
                                final app = _applications[index];
                                return _buildApplicationCard(app, theme);
                              },
                            ),
                          ),
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 56, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa nộp hồ sơ vào vị trí nào',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy duyệt danh sách việc làm để tìm cơ hội phù hợp!',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/jobs'),
            child: const Text('Khám phá việc làm ngay'),
          ),
        ],
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
    final metaTags = app.metaTags;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openApplicationDetail(app),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Title & Status Chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      app.jobTitle,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      ApplicationLabels.statusLabel(app.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (metaTags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in metaTags)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // Metadata: Date & AI Match Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (app.createdAt != null)
                    Text(
                      'Ngày nộp: ${DateFormat('dd/MM/yyyy HH:mm').format(app.createdAt!)}',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                  if (app.matchingScore != null)
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Điểm phù hợp AI: ${(app.matchingScore! * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (app.stageName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Vòng hiện tại: ${app.stageName}',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Xem lịch sử & đánh giá chi tiết các vòng',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
