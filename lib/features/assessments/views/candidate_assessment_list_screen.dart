import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../applications/repositories/application_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/views/widgets/unauthenticated_prompt_view.dart';

enum AssessmentItemType { technicalTest, aiInterview }

class CompletedAssessmentItem {
  final String id;
  final AssessmentItemType type;
  final String title;
  final String jobTitle;
  final int applicationId;
  final String status;
  final double? score;
  final double? passingScore;
  final bool? passed;
  final DateTime? completedAt;
  final String? summary;
  final String? strengths;
  final String? weaknesses;
  final Map<String, double> criteria;

  const CompletedAssessmentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.jobTitle,
    required this.applicationId,
    required this.status,
    this.score,
    this.passingScore,
    this.passed,
    this.completedAt,
    this.summary,
    this.strengths,
    this.weaknesses,
    this.criteria = const {},
  });
}

class CandidateAssessmentListScreen extends StatefulWidget {
  const CandidateAssessmentListScreen({super.key});

  @override
  State<CandidateAssessmentListScreen> createState() => _CandidateAssessmentListScreenState();
}

class _CandidateAssessmentListScreenState extends State<CandidateAssessmentListScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<CompletedAssessmentItem> _items = const [];
  String _filterType = 'ALL'; // ALL, TEST, AI

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _loadCompletedAssessments();
    }
  }

  Future<void> _loadCompletedAssessments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appRepo = getIt<ApplicationRepository>();
      final applications = await appRepo.getMyApplications();

      final List<CompletedAssessmentItem> gathered = [];

      await Future.wait(applications.map((app) async {
        try {
          final eval = await appRepo.getApplicationEvaluation(app.id);

          // 1. Technical assessments
          for (final a in eval.assessments) {
            gathered.add(
              CompletedAssessmentItem(
                id: 'assessment_${a.id}',
                type: AssessmentItemType.technicalTest,
                title: a.testTitle,
                jobTitle: app.jobTitle,
                applicationId: app.id,
                status: a.status,
                score: a.score,
                passingScore: a.passingScore,
                passed: a.passed,
                completedAt: a.submittedAt,
              ),
            );
          }

          // 2. AI Interviews
          for (final ai in eval.aiInterviews) {
            gathered.add(
              CompletedAssessmentItem(
                id: 'ai_${ai.id}',
                type: AssessmentItemType.aiInterview,
                title: 'Phỏng vấn AI (Lần ${ai.attemptNumber})',
                jobTitle: app.jobTitle,
                applicationId: app.id,
                status: ai.status,
                score: ai.score,
                passingScore: ai.passingScore,
                passed: ai.passed,
                completedAt: ai.completedAt,
                summary: ai.summary,
                strengths: ai.strengths,
                weaknesses: ai.weaknesses,
                criteria: ai.criteria,
              ),
            );
          }
        } catch (_) {
          // Bỏ qua nếu hồ sơ chưa mở vòng đánh giá
        }
      }));

      // Sắp xếp bài mới nhất lên đầu
      gathered.sort((a, b) {
        if (a.completedAt == null && b.completedAt == null) return 0;
        if (a.completedAt == null) return 1;
        if (b.completedAt == null) return -1;
        return b.completedAt!.compareTo(a.completedAt!);
      });

      if (mounted) {
        setState(() {
          _items = gathered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<CompletedAssessmentItem> get _filteredItems {
    if (_filterType == 'TEST') {
      return _items.where((e) => e.type == AssessmentItemType.technicalTest).toList();
    }
    if (_filterType == 'AI') {
      return _items.where((e) => e.type == AssessmentItemType.aiInterview).toList();
    }
    return _items;
  }

  void _showScoreDetailModal(CompletedAssessmentItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final hasScore = item.score != null;
        final isPassed = item.passed == true;
        final isFailed = item.passed == false;

        final Color resultColor = isPassed
            ? const Color(0xFF059669)
            : (isFailed ? const Color(0xFFDC2626) : const Color(0xFF2563EB));
        final Color resultBg = isPassed
            ? const Color(0xFFECFDF5)
            : (isFailed ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF));

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Drag Handle & Title
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
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.type == AssessmentItemType.aiInterview
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.type == AssessmentItemType.aiInterview
                              ? Icons.smart_toy_outlined
                              : Icons.quiz_outlined,
                          color: item.type == AssessmentItemType.aiInterview
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFEA580C),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.jobTitle,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFF94A3B8),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Big Score Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: resultBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: resultColor.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'KẾT QUẢ ĐIỂM SỐ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: resultColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              hasScore ? item.score!.toStringAsFixed(1) : '--',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: resultColor,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ 100',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: resultColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Outcome Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: resultColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isPassed
                                ? 'ĐẠT YÊU CẦU'
                                : (isFailed ? 'CHƯA ĐẠT' : 'ĐANG XỬ LÝ KẾT QUẢ'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        if (item.passingScore != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Điểm chuẩn tối thiểu: ${item.passingScore!.toStringAsFixed(1)} điểm',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Metadata Info List
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Thời gian nộp bài',
                          value: item.completedAt != null
                              ? DateFormat('dd/MM/yyyy HH:mm').format(item.completedAt!)
                              : 'Chưa cập nhật',
                        ),
                        const Divider(height: 18, color: Color(0xFFE2E8F0)),
                        _buildMetaRow(
                          icon: Icons.work_outline_rounded,
                          label: 'Đơn ứng tuyển',
                          value: item.jobTitle,
                        ),
                        const Divider(height: 18, color: Color(0xFFE2E8F0)),
                        _buildMetaRow(
                          icon: Icons.verified_outlined,
                          label: 'Hình thức đánh giá',
                          value: item.type == AssessmentItemType.aiInterview
                              ? 'Phỏng vấn thông minh cùng AI'
                              : 'Bài kiểm tra trắc nghiệm & kỹ thuật',
                        ),
                      ],
                    ),
                  ),

                  // AI Evaluation feedback (nếu có)
                  if (item.type == AssessmentItemType.aiInterview) ...[
                    if (item.summary != null && item.summary!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Nhận xét từ AI',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          item.summary!,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],

                    if (item.criteria.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Điểm theo tiêu chí',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...item.criteria.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              Text(
                                '${entry.value.toStringAsFixed(1)} / 10',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],

                  const SizedBox(height: 18),

                  // Security & Privacy Note (Rõ ràng chỉ xem được điểm số)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFFB45309)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Theo quy chế khảo thí của SmartHire, hệ thống chỉ hiển thị tổng điểm số và kết quả đánh giá. Nội dung chi tiết câu hỏi và đáp án không được công khai để bảo mật ngân hàng đề.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.45,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;

    if (authState is! Authenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bài Test & Phỏng Vấn AI'),
        ),
        body: const UnauthenticatedPromptView(
          icon: Icons.smart_toy_outlined,
          title: 'Đăng nhập để xem kết quả đánh giá',
          description:
              'Đăng nhập tài khoản ứng viên để theo dõi điểm số các bài kiểm tra trắc nghiệm và phỏng vấn AI bạn đã thực hiện.',
          buttonLabel: 'Đăng nhập ngay',
        ),
      );
    }

    final displayItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài Test & Phỏng Vấn AI'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _loadCompletedAssessments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip('ALL', 'Tất cả (${_items.length})', Icons.dashboard_outlined, theme),
                  const SizedBox(width: 8),
                  _buildTabChip(
                    'TEST',
                    'Bài Test Kỹ Thuật (${_items.where((e) => e.type == AssessmentItemType.technicalTest).length})',
                    Icons.quiz_outlined,
                    theme,
                  ),
                  const SizedBox(width: 8),
                  _buildTabChip(
                    'AI',
                    'Phỏng Vấn AI (${_items.where((e) => e.type == AssessmentItemType.aiInterview).length})',
                    Icons.smart_toy_outlined,
                    theme,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Main List Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadCompletedAssessments,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : displayItems.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _loadCompletedAssessments,
                            child: ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                                const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 64,
                                  color: Color(0xFFCBD5E1),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Chưa có bài test nào hoàn thành',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Khi bạn hoàn thành các bài đánh giá kỹ năng hoặc phỏng vấn AI theo yêu cầu của nhà tuyển dụng, kết quả điểm số sẽ hiển thị tại đây.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.go('/jobs'),
                                    icon: const Icon(Icons.work_outline_rounded, size: 18),
                                    label: const Text('Khám phá cơ hội việc làm'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCompletedAssessments,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                              itemCount: displayItems.length,
                              itemBuilder: (context, index) {
                                final item = displayItems[index];
                                final isPassed = item.passed == true;
                                final isFailed = item.passed == false;
                                final hasScore = item.score != null;

                                final Color badgeColor = isPassed
                                    ? const Color(0xFF059669)
                                    : (isFailed ? const Color(0xFFDC2626) : const Color(0xFF2563EB));
                                final Color badgeBg = isPassed
                                    ? const Color(0xFFECFDF5)
                                    : (isFailed ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF));

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
                                      onTap: () => _showScoreDetailModal(item),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Top Row: Avatar + Title & Job + Score Pill
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color: item.type == AssessmentItemType.aiInterview
                                                        ? const Color(0xFFEFF6FF)
                                                        : const Color(0xFFFFF7ED),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      item.type == AssessmentItemType.aiInterview
                                                          ? Icons.smart_toy_outlined
                                                          : Icons.quiz_outlined,
                                                      color: item.type == AssessmentItemType.aiInterview
                                                          ? const Color(0xFF2563EB)
                                                          : const Color(0xFFEA580C),
                                                      size: 20,
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
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 14.5,
                                                          fontWeight: FontWeight.w700,
                                                          height: 1.3,
                                                          color: Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                      if (item.jobTitle.trim().isNotEmpty) ...[
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          item.jobTitle.trim(),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                            color: Color(0xFF64748B),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  constraints: const BoxConstraints(maxWidth: 130),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: badgeBg,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        hasScore ? '${item.score!.toStringAsFixed(1)} đ' : 'Chưa chấm',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w800,
                                                          color: badgeColor,
                                                        ),
                                                      ),
                                                      if (hasScore || isPassed || isFailed) ...[
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                                          child: Text(
                                                            '·',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w900,
                                                              color: badgeColor.withValues(alpha: 0.6),
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          isPassed ? 'Đạt' : (isFailed ? 'Chưa đạt' : 'Đã nộp'),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w700,
                                                            color: badgeColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            // Bottom Row: Date & Action "Xem chi tiết điểm >"
                                            Container(
                                              padding: const EdgeInsets.only(top: 8),
                                              decoration: const BoxDecoration(
                                                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        if (item.completedAt != null) ...[
                                                          const Icon(
                                                            Icons.calendar_today_outlined,
                                                            size: 12,
                                                            color: Color(0xFF94A3B8),
                                                          ),
                                                          const SizedBox(width: 5),
                                                          Expanded(
                                                            child: Text(
                                                              DateFormat('dd/MM/yyyy').format(item.completedAt!),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(
                                                                fontSize: 11.5,
                                                                color: Color(0xFF94A3B8),
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ] else
                                                          const Expanded(
                                                            child: Text(
                                                              'Đã hoàn thành',
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Xem chi tiết điểm',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: theme.colorScheme.primary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Icon(
                                                        Icons.chevron_right_rounded,
                                                        size: 16,
                                                        color: theme.colorScheme.primary,
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
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String key, String label, IconData icon, ThemeData theme) {
    final isSelected = _filterType == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
