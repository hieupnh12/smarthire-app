import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../models/application_model.dart';
import '../../repositories/application_repository.dart';
import '../../utils/application_labels.dart';

enum EvaluationRoundKey { cv, aiInterview, assessment }

extension EvaluationRoundKeyX on EvaluationRoundKey {
  String get title {
    switch (this) {
      case EvaluationRoundKey.cv:
        return 'Sàng lọc CV';
      case EvaluationRoundKey.aiInterview:
        return 'Phỏng vấn AI';
      case EvaluationRoundKey.assessment:
        return 'Bài đánh giá';
    }
  }

  IconData get icon {
    switch (this) {
      case EvaluationRoundKey.cv:
        return Icons.description_outlined;
      case EvaluationRoundKey.aiInterview:
        return Icons.smart_toy_outlined;
      case EvaluationRoundKey.assessment:
        return Icons.assignment_turned_in_outlined;
    }
  }
}

class RoundSummaryCard extends StatelessWidget {
  final EvaluationRoundKey roundKey;
  final RoundItemModel? round;
  final bool selected;
  final VoidCallback onTap;

  const RoundSummaryCard({
    super.key,
    required this.roundKey,
    required this.round,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = round?.status ?? 'NOT_STARTED';
    final statusLabel = ApplicationLabels.roundStatusLabel(status);
    final badgeColor = ApplicationLabels.outcomeColor(
      passed: round?.passed,
      status: status,
      theme: theme,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: selected ? 1.6 : 0.9,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(roundKey.icon, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          roundKey.title,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (round?.score != null)
                    Text(
                      'Điểm: ${ApplicationLabels.formatScore(round!.score!)}${round?.threshold != null ? ' / ngưỡng ${ApplicationLabels.formatScore(round!.threshold!)}' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                  else
                    Text(
                      'Chưa có điểm — chạm để xem chi tiết vòng',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class RoundEvaluationPanel extends StatelessWidget {
  final EvaluationRoundKey roundKey;
  final CandidateEvaluationModel? evaluation;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const RoundEvaluationPanel({
    super.key,
    required this.roundKey,
    required this.evaluation,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết đánh giá · ${roundKey.title}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Điểm so với ngưỡng đạt và nhận xét chi tiết của hệ thống.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 14),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else if (error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Tải lại đánh giá'),
                  ),
                ],
              )
            else
              _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final data = evaluation;
    if (data == null) {
      return const _EmptyEvaluationBox(
        message: 'Vòng này chưa diễn ra hoặc chưa có kết quả đánh giá.',
      );
    }

    switch (roundKey) {
      case EvaluationRoundKey.cv:
        if (data.cv == null) {
          return const _EmptyEvaluationBox(
            message: 'CV chưa hoàn tất phân tích hoặc chưa có điểm sàng lọc.',
          );
        }
        return _CvEvaluationContent(cv: data.cv!);

      case EvaluationRoundKey.aiInterview:
        if (data.aiInterviews.isEmpty) {
          return const _EmptyEvaluationBox(
            message: 'Chưa có lượt phỏng vấn AI nào được ghi nhận.',
          );
        }
        return Column(
          children: [
            for (int i = 0; i < data.aiInterviews.length; i++) ...[
              _AiInterviewAttemptCard(
                attempt: data.aiInterviews[i],
                totalAttempts: data.aiInterviews.length,
              ),
              if (i < data.aiInterviews.length - 1) const SizedBox(height: 12),
            ],
          ],
        );

      case EvaluationRoundKey.assessment:
        if (data.assessments.isEmpty) {
          return const _EmptyEvaluationBox(
            message: 'Chưa có bài đánh giá nào cho hồ sơ này.',
          );
        }
        return Column(
          children: [
            for (int i = 0; i < data.assessments.length; i++) ...[
              _AssessmentAttemptCard(item: data.assessments[i]),
              if (i < data.assessments.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
    }
  }
}

class _EmptyEvaluationBox extends StatelessWidget {
  final String message;

  const _EmptyEvaluationBox({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  final double score;
  final double? threshold;
  final bool? passed;

  const _ScoreLine({
    required this.score,
    required this.threshold,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = threshold == null ? null : score - threshold!;
    final scoreColor = gap == null
        ? theme.colorScheme.onSurface
        : (gap < 0 ? theme.colorScheme.error : Colors.green.shade700);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text.rich(
          TextSpan(
            text: 'Điểm ',
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(
                text: ApplicationLabels.formatScore(score),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              if (threshold != null)
                TextSpan(
                  text: ' / ngưỡng ${ApplicationLabels.formatScore(threshold!)}',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                ),
            ],
          ),
        ),
        if (gap != null && passed == false && gap < 0)
          Text(
            '(thiếu ${ApplicationLabels.formatScore(-gap)} điểm)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}

class _CvEvaluationContent extends StatelessWidget {
  final CvEvaluationModel cv;

  const _CvEvaluationContent({required this.cv});

  String _fallbackAdvice() {
    final parts = <String>[];
    if (cv.requiredMissingSkills.isNotEmpty) {
      parts.add(
        'CV chưa nêu rõ các kỹ năng bắt buộc: ${cv.requiredMissingSkills.join(', ')}. Hãy bổ sung cụ thể bạn đã dùng từng kỹ năng ở dự án hoặc công việc nào.',
      );
    }
    if (cv.partialSkills.isNotEmpty) {
      parts.add(
        'Một số kỹ năng khớp một phần (${cv.partialSkills.join(', ')}). Hãy thêm ví dụ, thời gian và kết quả đạt được.',
      );
    }
    if (cv.passed) {
      parts.add('CV đã đáp ứng các yêu cầu chính của vị trí.');
    } else if (cv.requiredMissingSkills.isEmpty) {
      parts.add('Điểm sàng lọc chưa đạt ngưỡng yêu cầu. Hãy đối chiếu mô tả công việc để bổ sung kinh nghiệm hoặc kỹ năng còn thiếu.');
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final optionalMissing = cv.missingSkills
        .where((skill) => !cv.requiredMissingSkills.contains(skill))
        .toList();
    final advice = (cv.candidateAdvice?.trim().isNotEmpty == true)
        ? cv.candidateAdvice!.trim()
        : _fallbackAdvice();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScoreLine(score: cv.score, threshold: cv.threshold, passed: cv.passed),
        if (cv.passed && cv.threshold != null && cv.score < cv.threshold!) ...[
          const SizedBox(height: 10),
          _SectionText(
            title: 'Kết quả vòng',
            body: 'Điểm chưa đạt ngưỡng nhưng nhà tuyển dụng đã xem xét và duyệt bạn qua vòng này.',
          ),
        ],
        if (cv.explanation?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _SectionText(title: 'Nhận xét', body: cv.explanation!.trim()),
        ],
        if (advice.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      cv.candidateAdvice?.trim().isNotEmpty == true
                          ? 'Lời khuyên của AI'
                          : 'Gợi ý rút kinh nghiệm',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(advice, style: const TextStyle(fontSize: 13, height: 1.45)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        const Text(
          'Kỹ năng so với yêu cầu công việc',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (cv.matchedSkills.isEmpty &&
            cv.partialSkills.isEmpty &&
            cv.missingSkills.isEmpty &&
            cv.requiredMissingSkills.isEmpty)
          Text(
            'Công việc không khai báo danh sách kỹ năng cụ thể.',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in cv.matchedSkills)
                _SkillChip(label: s, kind: _SkillChipKind.match),
              for (final s in cv.partialSkills)
                _SkillChip(label: s, kind: _SkillChipKind.partial),
              for (final s in cv.requiredMissingSkills)
                _SkillChip(label: '$s · bắt buộc', kind: _SkillChipKind.missing),
              for (final s in optionalMissing)
                _SkillChip(label: s, kind: _SkillChipKind.missing),
            ],
          ),
        if (cv.requiredYears != null || cv.requiredEducation != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              if (cv.requiredYears != null)
                Expanded(
                  child: _FactBox(
                    label: 'Kinh nghiệm',
                    value: '${ApplicationLabels.formatScore(cv.candidateYears ?? 0)} năm',
                    hint: 'Yêu cầu ${ApplicationLabels.formatScore(cv.requiredYears!)} năm',
                    warning: (cv.candidateYears ?? 0) < cv.requiredYears!,
                  ),
                ),
              if (cv.requiredYears != null && cv.requiredEducation != null)
                const SizedBox(width: 10),
              if (cv.requiredEducation != null)
                Expanded(
                  child: _FactBox(
                    label: 'Học vấn',
                    value: cv.candidateEducation ?? 'Không xác định',
                    hint: 'Yêu cầu ${cv.requiredEducation!}',
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AiInterviewAttemptCard extends StatelessWidget {
  final AiInterviewEvaluationModel attempt;
  final int totalAttempts;

  const _AiInterviewAttemptCard({
    required this.attempt,
    required this.totalAttempts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outcomeColor = ApplicationLabels.outcomeColor(
      passed: attempt.passed,
      status: attempt.status,
      theme: theme,
    );
    final outcomeText = ApplicationLabels.outcomeLabel(
      passed: attempt.passed,
      status: attempt.status,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalAttempts > 1 ? 'Lượt ${attempt.attemptNumber}' : 'Kết quả phỏng vấn AI',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (attempt.completedAt != null)
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(attempt.completedAt!),
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: outcomeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  outcomeText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: outcomeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (attempt.score != null)
            _ScoreLine(
              score: attempt.score!,
              threshold: attempt.passingScore,
              passed: attempt.passed,
            )
          else
            Text(
              'Chưa có điểm cho lượt phỏng vấn này.',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
            ),
          if (attempt.summary?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _SectionText(title: 'Tổng quan', body: attempt.summary!.trim()),
          ],
          if (attempt.strengths?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _SectionText(title: 'Điểm mạnh', body: attempt.strengths!.trim()),
          ],
          if (attempt.weaknesses?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _SectionText(title: 'Cần cải thiện', body: attempt.weaknesses!.trim()),
          ],
          if (attempt.criteria.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Điểm theo tiêu chí',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final entry in attempt.criteria.entries) ...[
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      ApplicationLabels.criteriaLabel(entry.key),
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (entry.value / 100).clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 34,
                    child: Text(
                      ApplicationLabels.formatScore(entry.value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}

class _AssessmentAttemptCard extends StatefulWidget {
  final AssessmentEvaluationModel item;

  const _AssessmentAttemptCard({required this.item});

  @override
  State<_AssessmentAttemptCard> createState() => _AssessmentAttemptCardState();
}

class _AssessmentAttemptCardState extends State<_AssessmentAttemptCard> {
  bool _expanded = false;
  bool _loadingDetail = false;
  String? _detailError;
  AssessmentSubmissionDetailModel? _submission;

  Future<void> _toggleDetail() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    setState(() => _expanded = true);
    if (_submission != null || widget.item.id <= 0) return;

    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });

    try {
      final sub = await getIt<ApplicationRepository>().getSubmissionDetail(widget.item.id);
      if (!mounted) return;
      setState(() {
        _submission = sub;
        _loadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = e.toString().replaceAll('Exception: ', '');
        _loadingDetail = false;
      });
    }
  }

  String _pendingReason(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
      case 'PENDING':
        return 'Bài làm đang trong hàng đợi chấm tự động.';
      case 'GRADING':
        return 'Hệ thống đang chạy test case và đánh giá AI...';
      case 'FAILED':
        return 'Chấm tự động thất bại. Nhà tuyển dụng sẽ hỗ trợ chấm điểm.';
      case 'EXPIRED':
        return 'Bài làm đã hết thời gian trước khi nộp nên không được tính điểm.';
      default:
        return 'Chưa có điểm cho bài kiểm tra này.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final outcomeColor = ApplicationLabels.outcomeColor(
      passed: item.passed,
      status: item.status,
      theme: theme,
    );
    final outcomeText = ApplicationLabels.outcomeLabel(
      passed: item.passed,
      status: item.status,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.testTitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (item.submittedAt != null)
                      Text(
                        'Nộp lúc ${DateFormat('dd/MM/yyyy HH:mm').format(item.submittedAt!)}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: outcomeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  outcomeText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: outcomeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (item.score != null)
            _ScoreLine(
              score: item.score!,
              threshold: item.passingScore,
              passed: item.passed,
            )
          else
            Text(
              _pendingReason(item.status),
              style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
            ),
          if (item.id > 0) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _toggleDetail,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(
                _expanded ? Icons.expand_less_rounded : Icons.auto_awesome_outlined,
                size: 16,
              ),
              label: Text(
                _expanded ? 'Ẩn đánh giá chi tiết từng câu' : 'Xem đánh giá chi tiết từng câu (AI)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (_expanded) ...[
            const SizedBox(height: 10),
            if (_loadingDetail)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_detailError != null)
              Text(
                _detailError!,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
              )
            else if (_submission != null)
              _buildEvaluatedQuestions(context, _submission!),
          ],
        ],
      ),
    );
  }

  Widget _buildEvaluatedQuestions(
    BuildContext context,
    AssessmentSubmissionDetailModel sub,
  ) {
    final theme = Theme.of(context);
    final qById = {for (final q in sub.questions) q.id: q};
    final evaluated = sub.answers.where((a) => a.hasEvaluation).toList();

    if (evaluated.isEmpty) {
      return Text(
        'Chưa có nhận xét chi tiết cho từng câu hỏi.',
        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
      );
    }

    return Column(
      children: [
        for (final ans in evaluated) ...[
          _QuestionEvaluationItem(
            question: qById[ans.questionId],
            answer: ans,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _QuestionEvaluationItem extends StatelessWidget {
  final SubmissionQuestionModel? question;
  final SubmissionAnswerModel answer;

  const _QuestionEvaluationItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eval = answer.evaluation ?? const <String, dynamic>{};
    final codeReview = (eval['code_review'] is Map<String, dynamic>)
        ? eval['code_review'] as Map<String, dynamic>
        : eval;
    final type = question?.questionType.toUpperCase() ?? '';
    final isCoding = type == 'CODING';
    final isEssay = type == 'ESSAY';
    final typeLabel = isCoding
        ? 'Lập trình'
        : (isEssay ? 'Tự luận' : 'Trắc nghiệm');

    final testsPassed = eval['passed'] != null && eval['total'] != null
        ? '${eval['passed']}/${eval['total']}'
        : null;
    final timeComp = codeReview['time_complexity']?.toString();
    final spaceComp = codeReview['space_complexity']?.toString();
    final cleanCode = codeReview['clean_code']?.toString();
    final generalComment =
        (codeReview['general_comment'] ?? eval['general_comment'])?.toString();
    final hardcodeSuspected =
        (eval['hardcode_suspected'] == true) || (codeReview['hardcode_suspected'] == true);
    final criteria = eval['criteria_results'] is List
        ? (eval['criteria_results'] as List).whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];

    final q = question;
    final earnedScore = answer.score ?? answer.suggestedScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu ${q?.questionOrder ?? 1} · $typeLabel',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (earnedScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${ApplicationLabels.formatScore(earnedScore)} / ${q?.points ?? 0} đ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
            ],
          ),
          if (q != null && q.questionText.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              q.questionText.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
            ),
          ],
          if (isCoding &&
              (testsPassed != null || timeComp != null || spaceComp != null)) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (testsPassed != null)
                  _MetricBadge(label: 'Kiểm thử: $testsPassed', color: Colors.green.shade700),
                if (timeComp != null && timeComp.isNotEmpty)
                  _MetricBadge(label: 'Thời gian: $timeComp', color: Colors.indigo),
                if (spaceComp != null && spaceComp.isNotEmpty)
                  _MetricBadge(label: 'Bộ nhớ: $spaceComp', color: Colors.purple),
              ],
            ),
          ],
          if (hardcodeSuspected) ...[
            const SizedBox(height: 6),
            Text(
              'Cảnh báo: Phát hiện nghi vấn hardcode test case (áp trần 50% số điểm).',
              style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
            ),
          ],
          if (generalComment != null && generalComment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ApplicationLabels.localizeAiComment(generalComment),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (cleanCode != null && cleanCode.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '• ${ApplicationLabels.localizeAiComment(cleanCode)}',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
            ),
          ],
          if (isEssay && criteria.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Tiêu chí Rubric:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (int i = 0; i < criteria.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            criteria[i]['name']?.toString() ?? 'Tiêu chí ${i + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${criteria[i]['score_percent'] ?? 0}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (criteria[i]['feedback'] != null)
                      Text(
                        ApplicationLabels.localizeAiComment(criteria[i]['feedback'].toString()),
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MetricBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String title;
  final String body;

  const _SectionText({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, height: 1.45),
        ),
      ],
    );
  }
}

enum _SkillChipKind { match, partial, missing }

class _SkillChip extends StatelessWidget {
  final String label;
  final _SkillChipKind kind;

  const _SkillChip({required this.label, required this.kind});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (kind) {
      case _SkillChipKind.match:
        color = Colors.green.shade700;
        icon = Icons.check_rounded;
      case _SkillChipKind.partial:
        color = Colors.amber.shade800;
        icon = Icons.remove_rounded;
      case _SkillChipKind.missing:
        color = Theme.of(context).colorScheme.error;
        icon = Icons.close_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}

class _FactBox extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final bool warning;

  const _FactBox({
    required this.label,
    required this.value,
    required this.hint,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
          const SizedBox(height: 2),
          Text(
            warning ? '$value (chưa đủ)' : value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: warning ? theme.colorScheme.error : theme.colorScheme.onSurface,
            ),
          ),
          Text(hint, style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}
