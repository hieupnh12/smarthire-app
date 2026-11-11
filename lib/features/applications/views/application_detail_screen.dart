import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../interviews/models/human_interview_model.dart';
import '../../interviews/repositories/interview_repository.dart';
import '../../interviews/views/widgets/interview_card.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';
import '../utils/application_labels.dart';
import 'widgets/round_evaluation_panel.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final int applicationId;
  final ApplicationModel? initialApplication;

  const ApplicationDetailScreen({
    super.key,
    required this.applicationId,
    this.initialApplication,
  });

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  ApplicationDetailModel? _detail;
  CandidateEvaluationModel? _evaluation;
  List<HumanInterviewModel> _humanInterviews = const [];
  bool _loadingDetail = true;
  bool _loadingEvaluation = true;
  String? _detailError;
  String? _evaluationError;
  EvaluationRoundKey _selectedRound = EvaluationRoundKey.cv;
  bool _userSelectedRound = false;
  bool _withdrawing = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loadingDetail = true;
      _loadingEvaluation = true;
      _detailError = null;
      _evaluationError = null;
    });

    await Future.wait([
      _fetchDetail(),
      _fetchEvaluation(),
      _fetchHumanInterviews(),
    ]);
  }

  Future<void> _fetchDetail() async {
    try {
      final detail = await getIt<ApplicationRepository>().getApplicationDetail(widget.applicationId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loadingDetail = false;
        if (!_userSelectedRound) {
          _selectedRound = _pickDefaultRound(detail, _evaluation);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = e.toString().replaceAll('Exception: ', '');
        _loadingDetail = false;
      });
    }
  }

  Future<void> _fetchEvaluation() async {
    try {
      final evaluation =
          await getIt<ApplicationRepository>().getApplicationEvaluation(widget.applicationId);
      if (!mounted) return;
      setState(() {
        _evaluation = evaluation;
        _loadingEvaluation = false;
        if (!_userSelectedRound) {
          _selectedRound = _pickDefaultRound(_detail, evaluation);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _evaluationError = e.toString().replaceAll('Exception: ', '');
        _loadingEvaluation = false;
      });
    }
  }

  Future<void> _fetchHumanInterviews() async {
    try {
      final all = await getIt<InterviewRepository>().getMyInterviews();
      if (!mounted) return;
      setState(() {
        _humanInterviews =
            all.where((item) => item.applicationId == widget.applicationId).toList();
      });
    } catch (_) {
      // Optional enrichment; main application detail stays unaffected.
    }
  }

  EvaluationRoundKey _pickDefaultRound(
    ApplicationDetailModel? detail,
    CandidateEvaluationModel? eval,
  ) {
    final status = detail?.status.toUpperCase() ?? '';
    if (status == 'INTERVIEW' && (eval?.aiInterviews.isNotEmpty ?? false)) {
      return EvaluationRoundKey.aiInterview;
    }
    if (status == 'ASSESSMENT' && (eval?.assessments.isNotEmpty ?? false)) {
      return EvaluationRoundKey.assessment;
    }
    if (eval?.assessments.isNotEmpty ?? false) return EvaluationRoundKey.assessment;
    if (eval?.aiInterviews.isNotEmpty ?? false) return EvaluationRoundKey.aiInterview;
    return EvaluationRoundKey.cv;
  }

  Future<void> _confirmWithdraw(ApplicationDetailModel detail) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _WithdrawConfirmDialog(jobTitle: detail.jobTitle),
    );

    if (reason == null || !mounted) return;

    setState(() => _withdrawing = true);
    try {
      await getIt<ApplicationRepository>().withdrawApplication(
        detail.id,
        reason: reason,
      );
      if (!mounted) return;
      setState(() => _withdrawing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã rút đơn ứng tuyển thành công.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      setState(() => _withdrawing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.initialApplication;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Ứng Tuyển'),
      ),
      body: _loadingDetail && _detail == null
          ? const Center(child: CircularProgressIndicator())
          : _detailError != null && _detail == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text(_detailError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAll,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeaderCard(theme, _detail, summary),
                      const SizedBox(height: 18),
                      if (_detail != null) ...[
                        _buildRoundsSection(theme, _detail!),
                        if (_humanInterviews.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildHumanInterviewsSection(theme),
                        ],
                        const SizedBox(height: 18),
                        _buildHistorySection(theme, _detail!.history),
                        if (_detail!.cvs.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildCvsSection(theme, _detail!.cvs),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(
    ThemeData theme,
    ApplicationDetailModel? detail,
    ApplicationModel? summary,
  ) {
    final jobTitle = detail?.jobTitle ?? summary?.jobTitle ?? 'Vị trí ứng tuyển';
    final status = detail?.status ?? summary?.status ?? 'NEW';
    final createdAt = detail?.createdAt ?? summary?.createdAt;
    final metaTags = detail?.metaTags ?? summary?.metaTags ?? const [];
    final jobId = detail?.jobId ?? summary?.jobId ?? 0;
    final statusColor = ApplicationLabels.statusColor(status, theme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn ứng tuyển #${widget.applicationId}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jobTitle,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    ApplicationLabels.statusLabel(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    'Ngày nộp: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ],
            if (metaTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in metaTags)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _PipelineStepper(status: status),
            if (detail?.rejectReason?.trim().isNotEmpty == true ||
                detail?.withdrawReason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  detail?.rejectReason?.trim().isNotEmpty == true
                      ? 'Lý do kết thúc: ${detail!.rejectReason}'
                      : 'Lý do rút đơn: ${detail!.withdrawReason}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (jobId > 0)
                  OutlinedButton.icon(
                    onPressed: () => context.push('/jobs/$jobId'),
                    icon: const Icon(Icons.work_outline_rounded, size: 16),
                    label: const Text('Xem công việc'),
                  ),
                if (status.toUpperCase() == 'HUMAN_INTERVIEW')
                  ElevatedButton.icon(
                    onPressed: () => context.push('/profile/interviews'),
                    icon: const Icon(Icons.event_available_outlined, size: 16),
                    label: const Text('Lịch phỏng vấn trực tiếp'),
                  ),
                if (detail != null && detail.withdrawable)
                  OutlinedButton.icon(
                    onPressed: _withdrawing ? null : () => _confirmWithdraw(detail),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: Text(_withdrawing ? 'Đang rút...' : 'Rút đơn'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundsSection(ThemeData theme, ApplicationDetailModel detail) {
    final rounds = detail.rounds;
    final roundItems = {
      EvaluationRoundKey.cv: rounds?.cv,
      EvaluationRoundKey.aiInterview: rounds?.aiInterview,
      EvaluationRoundKey.assessment: rounds?.assessment,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ĐÁNH GIÁ CHI TIẾT CÁC VÒNG',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Chạm vào từng vòng để xem điểm số, nhận xét AI và lý do kết quả.',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 10),
        for (final key in EvaluationRoundKey.values) ...[
          RoundSummaryCard(
            roundKey: key,
            round: roundItems[key],
            selected: _selectedRound == key,
            onTap: () => setState(() {
              _userSelectedRound = true;
              _selectedRound = key;
            }),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        RoundEvaluationPanel(
          roundKey: _selectedRound,
          evaluation: _evaluation,
          loading: _loadingEvaluation,
          error: _evaluationError,
          onRetry: _fetchEvaluation,
        ),
      ],
    );
  }

  Widget _buildHumanInterviewsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LỊCH PHỎNG VẤN TRỰC TIẾP',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        for (final interview in _humanInterviews)
          InterviewCard(
            interview: interview,
            compact: true,
            onTap: () async {
              await context.push('/profile/interviews/${interview.id}', extra: interview);
              if (mounted) {
                await _loadAll();
              }
            },
          ),
      ],
    );
  }

  Widget _buildHistorySection(ThemeData theme, List<ApplicationHistoryModel> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LỊCH SỬ TRẠNG THÁI & CÁC VÒNG',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: history.isEmpty
                ? Text(
                    'Chưa có lịch sử cập nhật mới.',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < history.length; i++)
                        _HistoryTimelineRow(
                          item: history[i],
                          isLast: i == history.length - 1,
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCvsSection(ThemeData theme, List<CvRefModel> cvs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CV ĐÃ NỘP',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (int i = 0; i < cvs.length; i++) ...[
                ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.primary),
                  title: Text(
                    cvs[i].originalFilename,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: cvs[i].createdAt != null
                      ? Text(
                          'Tải lên: ${DateFormat('dd/MM/yyyy HH:mm').format(cvs[i].createdAt!)}',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                        )
                      : null,
                  trailing: Text(
                    cvs[i].status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (i < cvs.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PipelineStepper extends StatelessWidget {
  final String status;

  const _PipelineStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = ApplicationLabels.pipelineSteps;
    final current = ApplicationLabels.pipelineIndex(status);
    final ended = current < 0;
    final hired = status.toUpperCase() == 'HIRED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (ended)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Quy trình ứng tuyển đã kết thúc',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < steps.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !ended && (i < current || (hired && i == current))
                              ? theme.colorScheme.primary
                              : Colors.white,
                          border: Border.all(
                            color: !ended && i <= current
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: !ended && i == current ? 2 : 1.5,
                          ),
                        ),
                        child: !ended && (i < current || (hired && i == current))
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: !ended && i == current
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline,
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[i].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: !ended && i == current ? FontWeight.bold : FontWeight.w500,
                          color: !ended && i <= current
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTimelineRow extends StatelessWidget {
  final ApplicationHistoryModel item;
  final bool isLast;

  const _HistoryTimelineRow({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toLabel = ApplicationLabels.statusLabel(item.toStatus);
    final fromLabel =
        item.fromStatus != null ? ApplicationLabels.statusLabel(item.fromStatus!) : null;
    final title = (fromLabel != null && fromLabel != toLabel)
        ? '$fromLabel → $toLabel'
        : toLabel;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                    border: Border.all(
                      color: theme.colorScheme.primaryContainer,
                      width: 2.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (item.createdAt != null)
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt!),
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                        ),
                    ],
                  ),
                  if (item.note != null && item.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.note!.trim(),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawConfirmDialog extends StatefulWidget {
  final String jobTitle;

  const _WithdrawConfirmDialog({required this.jobTitle});

  @override
  State<_WithdrawConfirmDialog> createState() => _WithdrawConfirmDialogState();
}

class _WithdrawConfirmDialogState extends State<_WithdrawConfirmDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rút đơn ứng tuyển?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bạn có chắc muốn rút hồ sơ khỏi vị trí "${widget.jobTitle}"?'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 2,
            maxLength: 255,
            decoration: const InputDecoration(
              labelText: 'Lý do (không bắt buộc)',
              hintText: 'Nhập lý do rút hồ sơ nếu có...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Xác nhận rút đơn'),
        ),
      ],
    );
  }
}
