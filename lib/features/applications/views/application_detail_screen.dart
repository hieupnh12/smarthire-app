import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/storage_service.dart';
import '../../interviews/models/human_interview_model.dart';
import '../../interviews/repositories/interview_repository.dart';
import '../../interviews/utils/interview_labels.dart';
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
  bool _isLoading = true;
  String? _errorMessage;
  String? _evaluationError;
  bool _withdrawing = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _evaluationError = null;
    });

    await Future.wait([
      _fetchDetail(),
      _fetchEvaluation(),
      _fetchHumanInterviews(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDetail() async {
    try {
      final detail =
          await getIt<ApplicationRepository>().getApplicationDetail(widget.applicationId);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _fetchEvaluation() async {
    try {
      final evaluation =
          await getIt<ApplicationRepository>().getApplicationEvaluation(widget.applicationId);
      if (!mounted) return;
      setState(() {
        _evaluation = evaluation;
        _evaluationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _evaluationError = e.toString().replaceAll('Exception: ', '');
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
    } catch (_) {}
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
        title: const Text('Chi Tiết Hồ Sơ'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _loadAll,
          ),
        ],
      ),
      body: _isLoading && _detail == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _detail == null
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      // 1. Header Card (gọn gàng, đầy đủ thông tin)
                      _buildHeaderCard(theme, _detail, summary),

                      const SizedBox(height: 14),

                      // 2. Stepper tiến độ 4 bước
                      _buildCompactStepper(theme, _detail?.status ?? summary?.status ?? 'NEW'),

                      const SizedBox(height: 14),

                      // 3. Kết quả đánh giá từng vòng
                      _buildEvaluationResultsSection(theme),

                      // 4. Lịch phỏng vấn trực tiếp
                      if (_humanInterviews.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildInterviewSection(theme),
                      ],

                      // 5. File CV đính kèm
                      if (_detail?.cvs.isNotEmpty ?? false) ...[
                        const SizedBox(height: 14),
                        _buildCvsSection(theme, _detail!.cvs),
                      ],

                      // 6. Lịch sử trạng thái
                      if (_detail?.history.isNotEmpty ?? false) ...[
                        const SizedBox(height: 14),
                        _buildCompactHistory(theme, _detail!.history),
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
    final statusColor = ApplicationLabels.statusColor(status, theme);
    final statusText = ApplicationLabels.statusLabel(status);
    final canWithdraw = detail?.withdrawable ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  jobTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Mã hồ sơ: #${detail?.id ?? summary?.id ?? widget.applicationId}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              if (createdAt != null) ...[
                const Text('·', style: TextStyle(color: Color(0xFFCBD5E1))),
                Text(
                  'Nộp ngày ${DateFormat('dd/MM/yyyy').format(createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ],
          ),
          if (canWithdraw) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _withdrawing ? null : () => _confirmWithdraw(detail!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.cancel_outlined, size: 14),
                label: const Text('Rút hồ sơ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactStepper(ThemeData theme, String status) {
    final current = ApplicationLabels.pipelineIndex(status);
    final ended = current < 0;
    final isHired = status.toUpperCase() == 'HIRED';

    const steps = ['Lọc CV', 'Bài test', 'Phỏng vấn', 'Kết quả'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = !ended && (index < current || (isHired && index == current));
          final isCurrent = !ended && index == current;

          final Color dotColor = isCompleted
              ? const Color(0xFF059669)
              : (isCurrent ? const Color(0xFF1E60EC) : const Color(0xFFE2E8F0));
          final Color textColor = isCompleted || isCurrent
              ? const Color(0xFF0F172A)
              : const Color(0xFF94A3B8);

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? dotColor : Colors.white,
                        border: Border.all(
                          color: dotColor,
                          width: isCurrent ? 2 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                            : Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCurrent ? dotColor : Colors.transparent,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: isCompleted ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEvaluationResultsSection(ThemeData theme) {
    final eval = _evaluation;
    final cv = eval?.cv;
    final assessments = eval?.assessments ?? const [];
    final aiInterviews = eval?.aiInterviews ?? const [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KẾT QUẢ ĐÁNH GIÁ & FEEDBACK',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          // Vòng 1: Lọc CV
          _buildSelectableRoundRow(
            theme: theme,
            roundKey: EvaluationRoundKey.cv,
            icon: Icons.description_outlined,
            title: 'Sàng lọc hồ sơ CV',
            scoreText: cv != null ? '${cv.score.toStringAsFixed(1)} / 100' : 'Đang xử lý',
            statusTag: cv != null
                ? (cv.passed ? 'ĐẠT' : 'CHƯA ĐẠT')
                : 'ĐANG XỬ LÝ',
            isPassed: cv?.passed,
            onTap: () => _openRoundEvaluationSheet(EvaluationRoundKey.cv),
          ),

          const SizedBox(height: 8),

          // Vòng 2: Bài test kỹ thuật
          _buildSelectableRoundRow(
            theme: theme,
            roundKey: EvaluationRoundKey.assessment,
            icon: Icons.quiz_outlined,
            title: assessments.isNotEmpty ? assessments.first.testTitle : 'Bài test năng lực',
            scoreText: assessments.isNotEmpty && assessments.first.score != null
                ? '${assessments.first.score!.toStringAsFixed(1)} / 100'
                : (assessments.isNotEmpty ? 'Chưa có điểm' : '--'),
            statusTag: assessments.isNotEmpty
                ? (assessments.first.passed == true
                    ? 'ĐẠT'
                    : (assessments.first.passed == false
                        ? 'CHƯA ĐẠT'
                        : (assessments.first.status == 'SUBMITTED' ? 'ĐÃ NỘP' : 'CHƯA LÀM')))
                : 'CHƯA MỞ',
            isPassed: assessments.isNotEmpty ? assessments.first.passed : null,
            onTap: () => _openRoundEvaluationSheet(EvaluationRoundKey.assessment),
          ),

          const SizedBox(height: 8),

          // Vòng 3: Phỏng vấn AI
          _buildSelectableRoundRow(
            theme: theme,
            roundKey: EvaluationRoundKey.aiInterview,
            icon: Icons.smart_toy_outlined,
            title: aiInterviews.isNotEmpty
                ? 'Phỏng vấn AI (${aiInterviews.length} lượt)'
                : 'Phỏng vấn AI',
            scoreText: aiInterviews.isNotEmpty && aiInterviews.first.score != null
                ? '${aiInterviews.first.score!.toStringAsFixed(1)} / 100'
                : (aiInterviews.isNotEmpty ? 'Chưa có điểm' : '--'),
            statusTag: aiInterviews.isNotEmpty
                ? (aiInterviews.first.passed == true ? 'ĐẠT' : (aiInterviews.first.passed == false ? 'CHƯA ĐẠT' : 'CHƯA LÀM'))
                : 'CHƯA MỞ',
            isPassed: aiInterviews.isNotEmpty ? aiInterviews.first.passed : null,
            onTap: () => _openRoundEvaluationSheet(EvaluationRoundKey.aiInterview),
          ),
        ],
      ),
    );
  }

  void _openRoundEvaluationSheet(EvaluationRoundKey roundKey) {
    if (_evaluation == null) {
      _fetchEvaluation();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _EvaluationModalSheet(
          applicationId: widget.applicationId,
          roundKey: roundKey,
          jobTitle: _detail?.jobTitle ?? widget.initialApplication?.jobTitle ?? 'Vị trí ứng tuyển',
          initialEvaluation: _evaluation,
          initialError: _evaluationError,
          onEvaluationLoaded: (ev) {
            if (mounted) {
              setState(() => _evaluation = ev);
            }
          },
        );
      },
    );
  }

  Widget _buildSelectableRoundRow({
    required ThemeData theme,
    required EvaluationRoundKey roundKey,
    required IconData icon,
    required String title,
    required String scoreText,
    required String statusTag,
    required bool? isPassed,
    required VoidCallback onTap,
  }) {
    final Color badgeColor = isPassed == true
        ? const Color(0xFF059669)
        : (isPassed == false ? const Color(0xFFDC2626) : const Color(0xFF64748B));
    final Color badgeBg = isPassed == true
        ? const Color(0xFFECFDF5)
        : (isPassed == false ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    scoreText.contains('điểm') || scoreText.contains('Đang') || scoreText == '--'
                        ? scoreText
                        : 'Điểm: $scoreText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(maxWidth: 100),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                statusTag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewSection(ThemeData theme) {
    final tenantCode = getIt<StorageService>().getTenantCode();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LỊCH PHỎNG VẤN TRỰC TIẾP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          for (final interview in _humanInterviews) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          InterviewLabels.roundLabel(interview.round),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: InterviewLabels.statusColor(interview.status, theme).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          InterviewLabels.statusLabel(interview.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: InterviewLabels.statusColor(interview.status, theme),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event_outlined, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${DateFormat('dd/MM/yyyy · HH:mm').format(interview.start)} – ${DateFormat('HH:mm').format(interview.end)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        interview.mode.toUpperCase() == 'ONLINE'
                            ? Icons.videocam_outlined
                            : Icons.location_on_outlined,
                        size: 14,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          interview.mode.toUpperCase() == 'ONLINE'
                              ? InterviewLabels.providerLabel(interview.configuration.provider, interview.mode)
                              : (interview.location ?? 'Tại văn phòng'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                      if (interview.meetingUrl != null && interview.meetingUrl!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            final resolved = InterviewLabels.resolveMeetingUrl(interview.meetingUrl, tenantCode);
                            Clipboard.setData(ClipboardData(text: resolved));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã sao chép link phòng họp: $resolved'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 12, color: Color(0xFF1E60EC)),
                                SizedBox(width: 4),
                                Text(
                                  'Chép link',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E60EC)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildCvsSection(ThemeData theme, List<CvRefModel> cvs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HỒ SƠ CV ĐÍNH KÈM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          for (final cv in cvs)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, size: 22, color: Color(0xFFDC2626)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cv.originalFilename,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                        if (cv.createdAt != null)
                          Text(
                            'Tải lên ngày ${DateFormat('dd/MM/yyyy').format(cv.createdAt!)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactHistory(ThemeData theme, List<ApplicationHistoryModel> history) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LỊCH SỬ CẬP NHẬT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < history.take(4).length; i++) ...[
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ApplicationLabels.statusLabel(history[i].toStatus),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ),
                if (history[i].createdAt != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(history[i].createdAt!),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
            if (i < history.take(4).length - 1)
              const SizedBox(height: 8),
          ],
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

class _EvaluationModalSheet extends StatefulWidget {
  final int applicationId;
  final EvaluationRoundKey roundKey;
  final String jobTitle;
  final CandidateEvaluationModel? initialEvaluation;
  final String? initialError;
  final ValueChanged<CandidateEvaluationModel>? onEvaluationLoaded;

  const _EvaluationModalSheet({
    required this.applicationId,
    required this.roundKey,
    required this.jobTitle,
    required this.initialEvaluation,
    this.initialError,
    this.onEvaluationLoaded,
  });

  @override
  State<_EvaluationModalSheet> createState() => _EvaluationModalSheetState();
}

class _EvaluationModalSheetState extends State<_EvaluationModalSheet> {
  late CandidateEvaluationModel? _evaluation;
  late String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _evaluation = widget.initialEvaluation;
    _error = widget.initialError;
    if (_evaluation == null && _error == null) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ev = await getIt<ApplicationRepository>().getApplicationEvaluation(widget.applicationId);
      if (!mounted) return;
      setState(() {
        _evaluation = ev;
        _loading = false;
      });
      widget.onEvaluationLoaded?.call(ev);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCv = widget.roundKey == EvaluationRoundKey.cv;
    final isAssessment = widget.roundKey == EvaluationRoundKey.assessment;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header: Icon + Title + Job Title + Close Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isCv
                          ? const Color(0xFFEFF6FF)
                          : (isAssessment ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCv
                          ? Icons.description_outlined
                          : (isAssessment ? Icons.quiz_outlined : Icons.smart_toy_outlined),
                      size: 22,
                      color: isCv
                          ? const Color(0xFF2563EB)
                          : (isAssessment ? const Color(0xFFEA580C) : const Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết đánh giá · ${widget.roundKey.title}',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.jobTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Scrollable Evaluation Body
              Flexible(
                child: SingleChildScrollView(
                  child: RoundEvaluationPanel(
                    roundKey: widget.roundKey,
                    evaluation: _evaluation,
                    loading: _loading,
                    error: _error,
                    showCard: false,
                    onRetry: _fetchData,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
