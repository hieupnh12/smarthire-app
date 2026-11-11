import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injection.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../models/human_interview_model.dart';
import '../repositories/interview_repository.dart';
import 'widgets/interview_card.dart';

class InterviewScheduleScreen extends StatefulWidget {
  const InterviewScheduleScreen({super.key});

  @override
  State<InterviewScheduleScreen> createState() => _InterviewScheduleScreenState();
}

class _InterviewScheduleScreenState extends State<InterviewScheduleScreen> {
  List<HumanInterviewModel> _interviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInterviews();
  }

  Future<void> _fetchInterviews() async {
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
      final items = await getIt<InterviewRepository>().getMyInterviews();
      if (!mounted) return;
      setState(() {
        _interviews = items;
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

  Future<void> _openDetail(HumanInterviewModel item) async {
    await context.push('/profile/interviews/${item.id}', extra: item);
    if (mounted) {
      await _fetchInterviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final now = DateTime.now();

    final upcoming = _interviews.where((i) => i.isUpcoming(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final past = _interviews.where((i) => !i.isUpcoming(now)).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    final pendingCount = upcoming.where((i) => i.status == 'PROPOSED').length;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _fetchInterviews(),
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Phỏng Vấn'),
      ),
      body: authState is! Authenticated
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note_outlined, size: 56, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    const Text(
                      'Đăng nhập để xem lịch phỏng vấn',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Theo dõi giờ hẹn, link phòng họp và xác nhận tham dự với nhà tuyển dụng.',
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
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchInterviews,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _interviews.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _fetchInterviews,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 80),
                              Icon(Icons.calendar_today_outlined, size: 56, color: theme.colorScheme.outline),
                              const SizedBox(height: 16),
                              const Text(
                                'Chưa có lịch phỏng vấn nào',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Khi nhà tuyển dụng gửi lời mời phỏng vấn trực tiếp, lịch hẹn và chi tiết phòng họp sẽ hiển thị tại đây.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchInterviews,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _SummaryChip(
                                      label: 'Lịch sắp tới',
                                      value: '${upcoming.length}',
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SummaryChip(
                                      label: 'Chờ xác nhận',
                                      value: '$pendingCount',
                                      color: pendingCount > 0 ? Colors.orange.shade800 : theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (upcoming.isNotEmpty) ...[
                                Text(
                                  'SẮP TỚI',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final item in upcoming)
                                  InterviewCard(
                                    interview: item,
                                    onTap: () => _openDetail(item),
                                  ),
                                const SizedBox(height: 12),
                              ],
                              if (past.isNotEmpty) ...[
                                Text(
                                  'ĐÃ QUA / ĐÃ HỦY',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final item in past)
                                  Opacity(
                                    opacity: 0.78,
                                    child: InterviewCard(
                                      interview: item,
                                      onTap: () => _openDetail(item),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
