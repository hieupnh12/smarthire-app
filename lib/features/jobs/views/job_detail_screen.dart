import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../models/job_model.dart';
import '../repositories/job_repository.dart';
import '../../../core/di/injection.dart';

class JobDetailScreen extends StatefulWidget {
  final int jobId;
  final JobModel? initialJob;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    this.initialJob,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late JobModel? _job = widget.initialJob;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_job == null) {
      _loadJobDetail();
    }
  }

  Future<void> _loadJobDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final job = await getIt<JobRepository>().getJobDetail(widget.jobId);
      setState(() {
        _job = job;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onApplyPressed() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      // Yêu cầu đăng nhập trước khi nộp đơn
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Yêu cầu đăng nhập'),
          content: const Text(
            'Bạn cần đăng nhập tài khoản Ứng viên để nộp hồ sơ trực tiếp vào vị trí này.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/login');
              },
              child: const Text('Đăng nhập ngay'),
            ),
          ],
        ),
      );
      return;
    }

    _showApplyDialog();
  }

  void _showApplyDialog() {
    final noteController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nộp Đơn Ứng Tuyển',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Vị trí: ${_job?.title}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Thư giới thiệu / Ghi chú (Cover Note)',
                    hintText: 'Nêu ngắn gọn lý do bạn phù hợp với công việc này...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final errorColor = theme.colorScheme.error;
                          try {
                            await getIt<JobRepository>().applyJob(
                              jobId: widget.jobId,
                              coverNote: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Nộp hồ sơ thành công! AI đang sàng lọc CV của bạn.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: errorColor,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Xác Nhận Nộp Đơn'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _job == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(_errorMessage ?? 'Không tìm thấy công việc'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadJobDetail,
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      );
    }

    final job = _job!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Việc Làm'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: job.acceptingApplications ? _onApplyPressed : null,
            child: Text(
              job.acceptingApplications ? 'Nộp Đơn Ứng Tuyển Ngay' : 'Đã Hết Hạn Ứng Tuyển',
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Salary
            Text(
              job.title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              job.salary ?? 'Mức lương: Thỏa thuận',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Metadata Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (job.department != null)
                  _buildMetaChip(Icons.domain_rounded, job.department!, theme),
                if (job.location != null)
                  _buildMetaChip(Icons.location_on_outlined, job.location!, theme),
                if (job.employmentType != null)
                  _buildMetaChip(Icons.work_outline_rounded, job.employmentType!, theme),
                if (job.workMode != null)
                  _buildMetaChip(Icons.apartment_rounded, job.workMode!, theme),
                if (job.deadline != null)
                  _buildMetaChip(
                    Icons.event_outlined,
                    'Hạn nộp: ${DateFormat('dd/MM/yyyy').format(job.deadline!)}',
                    theme,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Skills
            if (job.skills.isNotEmpty) ...[
              Text(
                'Kỹ năng yêu cầu',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.skills.map((skill) {
                  return Chip(
                    label: Text(skill),
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Description
            if (job.description != null && job.description!.isNotEmpty) ...[
              Text(
                'Mô tả công việc',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                job.description!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
            ],

            // Responsibilities
            if (job.responsibilities != null && job.responsibilities!.isNotEmpty) ...[
              Text(
                'Trách nhiệm công việc',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                job.responsibilities!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
            ],

            // Benefits
            if (job.benefits != null && job.benefits!.isNotEmpty) ...[
              Text(
                'Quyền lợi được hưởng',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                job.benefits!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
