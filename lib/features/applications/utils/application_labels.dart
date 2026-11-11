import 'package:flutter/material.dart';

class PipelineStepMeta {
  final String id;
  final String label;
  final List<String> statuses;

  const PipelineStepMeta({
    required this.id,
    required this.label,
    required this.statuses,
  });
}

class ApplicationLabels {
  ApplicationLabels._();

  static const List<PipelineStepMeta> pipelineSteps = [
    PipelineStepMeta(id: 'cv', label: 'Lọc CV', statuses: ['NEW', 'IN_REVIEW', 'APPLIED', 'CV_SCREENING', 'SHORTLISTED']),
    PipelineStepMeta(id: 'ai', label: 'PV AI', statuses: ['INTERVIEW', 'INTERVIEWING']),
    PipelineStepMeta(id: 'test', label: 'Bài test', statuses: ['ASSESSMENT', 'TESTING']),
    PipelineStepMeta(id: 'human', label: 'PV trực tiếp', statuses: ['HUMAN_INTERVIEW']),
    PipelineStepMeta(id: 'decision', label: 'Kết quả', statuses: ['OFFER', 'OFFERED', 'HIRED']),
  ];

  static int pipelineIndex(String status) {
    final upper = status.toUpperCase();
    if (upper == 'REJECTED' || upper == 'FAILED' || upper == 'WITHDRAWN') return -1;
    final idx = pipelineSteps.indexWhere((s) => s.statuses.contains(upper));
    return idx < 0 ? 0 : idx;
  }

  static const Map<String, String> _statusLabels = {
    'NEW': 'Đã nộp',
    'APPLIED': 'Đã nộp',
    'IN_REVIEW': 'Đang xem xét',
    'CV_SCREENING': 'Đang lọc CV',
    'SHORTLISTED': 'Đã qua vòng CV',
    'ASSESSMENT': 'Bài đánh giá',
    'TESTING': 'Làm bài kiểm tra',
    'INTERVIEW': 'Phỏng vấn AI',
    'INTERVIEWING': 'Phỏng vấn AI',
    'HUMAN_INTERVIEW': 'Phỏng vấn trực tiếp',
    'OFFER': 'Đề nghị nhận việc',
    'OFFERED': 'Đề nghị nhận việc',
    'HIRED': 'Đã trúng tuyển',
    'REJECTED': 'Không phù hợp',
    'FAILED': 'Kết thúc quy trình',
    'WITHDRAWN': 'Đã rút đơn',
  };

  static const Map<String, String> _roundStatusLabels = {
    'PENDING': 'Đang chờ',
    'PASSED': 'Đạt',
    'FAILED': 'Chưa đạt',
    'COMPLETED': 'Hoàn tất',
    'NOT_STARTED': 'Chưa bắt đầu',
    'MISSING': 'Chưa bắt đầu',
    'INVITED': 'Đã mời',
    'CREATED': 'Đã mời',
    'GENERATING': 'Đang chuẩn bị',
    'QUESTIONS_READY': 'Sẵn sàng',
    'IN_PROGRESS': 'Đang làm',
    'SCORING': 'Đang chấm',
    'SCORED': 'Đã chấm',
    'ERROR': 'Đang xử lý lại',
    'SUBMITTED': 'Đang chờ chấm',
    'GRADING': 'Đang chấm',
    'GRADED': 'Đã chấm',
    'EXPIRED': 'Hết hạn',
  };

  static const Map<String, String> _criteriaLabels = {
    'TECHNICAL_KNOWLEDGE': 'Kiến thức chuyên môn',
    'PROBLEM_SOLVING': 'Giải quyết vấn đề',
    'REASONING': 'Lập luận',
    'COMMUNICATION': 'Giao tiếp',
    'PRACTICAL_EXPERIENCE': 'Kinh nghiệm thực tế',
    'BEHAVIORAL_SITUATIONAL': 'Hành vi & tình huống',
  };

  static String statusLabel(String status) =>
      _statusLabels[status.toUpperCase()] ?? status;

  static String roundStatusLabel(String status) =>
      _roundStatusLabels[status.toUpperCase()] ?? status;

  static String criteriaLabel(String key) =>
      _criteriaLabels[key.toUpperCase()] ?? key;

  static Color statusColor(String status, ThemeData theme) {
    switch (status.toUpperCase()) {
      case 'OFFER':
      case 'OFFERED':
      case 'HIRED':
      case 'PASSED':
        return Colors.green.shade700;
      case 'INTERVIEW':
      case 'INTERVIEWING':
      case 'HUMAN_INTERVIEW':
      case 'SCORED':
      case 'GRADED':
      case 'COMPLETED':
        return theme.colorScheme.primary;
      case 'ASSESSMENT':
      case 'TESTING':
      case 'IN_PROGRESS':
      case 'SCORING':
      case 'GRADING':
      case 'SUBMITTED':
      case 'INVITED':
        return Colors.orange.shade800;
      case 'REJECTED':
      case 'FAILED':
      case 'EXPIRED':
        return theme.colorScheme.error;
      case 'WITHDRAWN':
      case 'NOT_STARTED':
      case 'MISSING':
        return theme.colorScheme.outline;
      default:
        return theme.colorScheme.secondary;
    }
  }

  static Color outcomeColor({bool? passed, required String status, required ThemeData theme}) {
    if (passed == true) return Colors.green.shade700;
    if (passed == false) return theme.colorScheme.error;
    return statusColor(status, theme);
  }

  static String outcomeLabel({bool? passed, required String status}) {
    if (passed == true) return 'Đạt';
    if (passed == false) return 'Chưa đạt';
    return roundStatusLabel(status);
  }

  static String formatScore(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  static final List<(RegExp, String)> _aiCommentReplacements = [
    (
      RegExp(
        r'The code correctly implements the arithmetic progression formula to calculate the sum from 1 to n in O\(1\) time complexity\. It is clean, concise, and optimal\.',
        caseSensitive: false,
      ),
      'Mã nguồn cài đặt chính xác công thức cấp số cộng để tính tổng từ 1 đến n với độ phức tạp thời gian O(1). Thuật toán ngắn gọn, sạch sẽ và tối ưu.',
    ),
    (
      RegExp(
        r'The code is extremely clean, well-structured, and contains no unnecessary boilerplate\.',
        caseSensitive: false,
      ),
      'Mã nguồn rất sạch sẽ, cấu trúc rõ ràng và không có đoạn mã thừa thãi.',
    ),
    (
      RegExp(r'The code is clean, concise, and optimal\.', caseSensitive: false),
      'Mã nguồn sạch sẽ, ngắn gọn và tối ưu.',
    ),
    (
      RegExp(r'The code is clean, optimal, and follows good practices\.', caseSensitive: false),
      'Mã nguồn sạch, tối ưu và tuân thủ các quy ước lập trình chuẩn.',
    ),
    (
      RegExp(r'The code is well-structured and easy to read\.', caseSensitive: false),
      'Mã nguồn có cấu trúc tốt, rõ ràng và dễ đọc.',
    ),
    (
      RegExp(r'The solution is clean, concise, and optimal\.', caseSensitive: false),
      'Giải pháp sạch sẽ, ngắn gọn và tối ưu.',
    ),
    (
      RegExp(r'The solution is optimal\.', caseSensitive: false),
      'Giải pháp đạt mức tối ưu cao.',
    ),
    (
      RegExp(r'Time complexity is optimal\.', caseSensitive: false),
      'Độ phức tạp thời gian đạt mức tối ưu.',
    ),
    (
      RegExp(r'Space complexity is optimal\.', caseSensitive: false),
      'Độ phức tạp bộ nhớ đạt mức tối ưu.',
    ),
    (
      RegExp(r'No answer submitted', caseSensitive: false),
      'Chưa nộp câu trả lời.',
    ),
    (
      RegExp(r'All test cases passed successfully\.', caseSensitive: false),
      'Tất cả các ca kiểm thử đều vượt qua thành công.',
    ),
  ];

  static String localizeAiComment(String? text) {
    if (text == null) return '';
    var result = text.trim();
    for (final (pattern, replacement) in _aiCommentReplacements) {
      result = result.replaceAll(pattern, replacement);
    }
    return result;
  }
}

