import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/storage_service.dart';
import '../models/human_interview_model.dart';
import '../repositories/interview_repository.dart';
import '../utils/interview_labels.dart';

class InterviewDetailScreen extends StatefulWidget {
  final int interviewId;
  final HumanInterviewModel? initialInterview;

  const InterviewDetailScreen({
    super.key,
    required this.interviewId,
    this.initialInterview,
  });

  @override
  State<InterviewDetailScreen> createState() => _InterviewDetailScreenState();
}

class _InterviewDetailScreenState extends State<InterviewDetailScreen> {
  late HumanInterviewModel? _interview = widget.initialInterview;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail(showLoader: _interview == null);
  }

  Future<void> _loadDetail({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final fresh = await getIt<InterviewRepository>().getInterviewDetail(widget.interviewId);
      if (!mounted) return;
      setState(() {
        _interview = fresh;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_interview == null) {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAttendance() async {
    setState(() => _isSubmitting = true);
    try {
      final updated = await getIt<InterviewRepository>().confirmInterview(widget.interviewId);
      if (!mounted) return;
      setState(() {
        _interview = updated;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận tham dự buổi phỏng vấn.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _openRescheduleSheet(HumanInterviewModel interview) async {
    final updated = await showModalBottomSheet<HumanInterviewModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RescheduleBottomSheet(interview: interview),
    );

    if (updated != null && mounted) {
      setState(() => _interview = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi đề nghị đổi giờ tới nhà tuyển dụng.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _copyMeetingUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép link phòng họp')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _interview == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi Tiết Phỏng Vấn')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _interview == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi Tiết Phỏng Vấn')),
        body: Center(
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
                  onPressed: () => _loadDetail(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final interview = _interview!;
    final now = DateTime.now();
    final statusColor = InterviewLabels.statusColor(interview.status, theme);
    final isOnline = interview.mode.toUpperCase() == 'ONLINE';
    final tenantCode = getIt<StorageService>().getTenantCode();
    final resolvedMeetingUrl = InterviewLabels.resolveMeetingUrl(interview.meetingUrl, tenantCode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Phỏng Vấn'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadDetail(showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Header Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            InterviewLabels.statusLabel(interview.status),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            InterviewLabels.roundLabel(interview.round),
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      interview.jobTitle,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_rounded, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('dd/MM/yyyy').format(interview.start),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${DateFormat('HH:mm').format(interview.start)} – ${DateFormat('HH:mm').format(interview.end)} (${interview.durationMinutes} phút)',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Mode & Meeting / Location Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HÌNH THỨC & ĐỊA ĐIỂM',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: isOnline ? Icons.videocam_outlined : Icons.business_outlined,
                      label: isOnline ? 'Trực tuyến' : 'Trực tiếp',
                      value: InterviewLabels.providerLabel(interview.configuration.provider, interview.mode),
                    ),
                    const SizedBox(height: 12),
                    if (isOnline) ...[
                      _DetailRow(
                        icon: Icons.link_rounded,
                        label: 'Link phòng họp',
                        value: resolvedMeetingUrl.isNotEmpty
                            ? resolvedMeetingUrl
                            : 'Link phòng họp sẽ được gửi trước buổi phỏng vấn',
                      ),
                      if (resolvedMeetingUrl.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () => _copyMeetingUrl(resolvedMeetingUrl),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Sao chép link phòng họp'),
                          ),
                        ),
                      ],
                    ] else
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Địa điểm phỏng vấn',
                        value: interview.location?.isNotEmpty == true
                            ? interview.location!
                            : 'Địa điểm sẽ được thông báo sau',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Panel Participants
            if (interview.participants.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HỘI ĐỒNG PHỎNG VẤN',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final p in interview.participants)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(
                                      '${InterviewLabels.participantRoleLabel(p.role)}${p.email.isNotEmpty ? ' · ${p.email}' : ''}',
                                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Notes
            if (interview.configuration.notes?.trim().isNotEmpty == true) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GHI CHÚ TỪ NHÀ TUYỂN DỤNG',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        interview.configuration.notes!,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Reschedule Pending Banner
            if (interview.status == 'RESCHEDULE_REQUESTED') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.update_rounded, color: Colors.amber.shade900, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Đã gửi đề nghị đổi lịch',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                    if (interview.configuration.requestedStart != null &&
                        interview.configuration.requestedEnd != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Giờ mong muốn: ${DateFormat('dd/MM/yyyy HH:mm').format(interview.configuration.requestedStart!)} – ${DateFormat('HH:mm').format(interview.configuration.requestedEnd!)}',
                        style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                      ),
                    ],
                    if (interview.configuration.rescheduleReason?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lý do: ${interview.configuration.rescheduleReason}',
                        style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Actions
            if (interview.canConfirm(now)) ...[
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _confirmAttendance,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Xác nhận tham dự'),
              ),
              const SizedBox(height: 10),
            ],
            if (interview.canReschedule(now)) ...[
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => _openRescheduleSheet(interview),
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Đề nghị đổi giờ'),
              ),
              const SizedBox(height: 10),
            ],
            if (interview.applicationId > 0)
              TextButton.icon(
                onPressed: () => context.push('/applications/${interview.applicationId}'),
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('Xem chi tiết hồ sơ ứng tuyển & đánh giá các vòng'),
              ),
          ],
        ),
      ),
    );
  }
}

class _RescheduleBottomSheet extends StatefulWidget {
  final HumanInterviewModel interview;

  const _RescheduleBottomSheet({required this.interview});

  @override
  State<_RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<_RescheduleBottomSheet> {
  final _reasonController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _formError;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initialStart = widget.interview.start.isAfter(now.add(const Duration(hours: 1)))
        ? widget.interview.start
        : DateTime(now.year, now.month, now.day + 1, 9, 0);
    final duration = widget.interview.durationMinutes >= 15 &&
            widget.interview.durationMinutes <= 240
        ? widget.interview.durationMinutes
        : 60;
    final initialEnd = initialStart.add(Duration(minutes: duration));

    _selectedDate = DateTime(initialStart.year, initialStart.month, initialStart.day);
    _startTime = TimeOfDay.fromDateTime(initialStart);
    _endTime = TimeOfDay.fromDateTime(initialEnd);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _formError = null;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _formError = null;
      });
    }
  }

  Future<void> _submit() async {
    final proposedStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final proposedEnd = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    final reason = _reasonController.text.trim();
    final diffMinutes = proposedEnd.difference(proposedStart).inMinutes;

    if (!proposedStart.isAfter(DateTime.now())) {
      setState(() => _formError = 'Vui lòng chọn thời gian bắt đầu trong tương lai.');
      return;
    }
    if (diffMinutes < 15 || diffMinutes > 240) {
      setState(() => _formError = 'Thời lượng buổi phỏng vấn phải từ 15 đến 240 phút.');
      return;
    }
    if (reason.isEmpty) {
      setState(() => _formError = 'Vui lòng nhập lý do đổi lịch.');
      return;
    }

    setState(() {
      _sending = true;
      _formError = null;
    });

    try {
      final updated = await getIt<InterviewRepository>().requestReschedule(
        id: widget.interview.id,
        start: proposedStart,
        end: proposedEnd,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _formError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đề nghị đổi giờ phỏng vấn',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _sending ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Thời lượng hợp lệ từ 15–240 phút. Lịch hiện tại vẫn được giữ cho đến khi nhà tuyển dụng duyệt.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _sending ? null : _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text('Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sending ? null : () => _pickTime(isStart: true),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text('Bắt đầu: ${_startTime.format(context)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sending ? null : () => _pickTime(isStart: false),
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label: Text('Kết thúc: ${_endTime.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Lý do đề nghị đổi lịch *',
                hintText: 'Ví dụ: Trùng lịch làm việc/học tập, mong muốn dời sang buổi chiều...',
                alignLabelWithHint: true,
              ),
              onChanged: (_) {
                if (_formError != null) {
                  setState(() => _formError = null);
                }
              },
            ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(
                _formError!,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Gửi đề nghị đổi giờ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
