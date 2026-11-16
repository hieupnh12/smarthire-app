import 'package:flutter/material.dart';

class InterviewLabels {
  InterviewLabels._();

  static const Map<String, String> _roundLabels = {
    'TECHNICAL': 'Vòng Kỹ thuật',
    'CULTURE': 'Vòng Văn hóa & Lãnh đạo',
    'EXECUTIVE': 'Vòng Ban Giám Đốc',
    'HR': 'Vòng Phỏng Vấn HR',
    'ROUND_1': 'Phỏng Vấn Vòng 1',
    'ROUND_2': 'Phỏng Vấn Vòng 2',
    'ROUND_3': 'Phỏng Vấn Vòng 3',
  };

  static const Map<String, String> _statusLabels = {
    'DRAFT': 'Bản nháp',
    'PROPOSED': 'Chờ bạn xác nhận',
    'CONFIRMED': 'Đã xác nhận',
    'SCHEDULED': 'Đã lên lịch',
    'IN_PROGRESS': 'Đang diễn ra',
    'RESCHEDULE_REQUESTED': 'Đề nghị đổi giờ',
    'CANCELLED': 'Đã hủy',
    'DONE': 'Đã hoàn thành',
    'COMPLETED': 'Đã hoàn thành',
    'EVALUATED': 'Đã hoàn thành',
  };

  static const Map<String, String> _providerLabels = {
    'SMARTHIRE': 'Phòng họp SmartHire',
    'GOOGLE_MEET': 'Google Meet',
    'ZOOM': 'Zoom Meeting',
    'TEAMS': 'Microsoft Teams',
    'OFFICE': 'Tại văn phòng',
  };

  static const Map<String, String> _participantRoleLabels = {
    'LEAD': 'Trưởng hội đồng',
    'CO_INTERVIEWER': 'Thành viên phỏng vấn',
    'NOTE_TAKER': 'Thư ký',
  };

  static String roundLabel(String round) => _roundLabels[round.toUpperCase()] ?? round;

  static String statusLabel(String status) => _statusLabels[status.toUpperCase()] ?? status;

  static String providerLabel(String? provider, String mode) {
    if (provider != null && _providerLabels.containsKey(provider.toUpperCase())) {
      return _providerLabels[provider.toUpperCase()]!;
    }
    return mode.toUpperCase() == 'ONLINE' ? 'Trực tuyến' : 'Trực tiếp tại văn phòng';
  }

  static String participantRoleLabel(String role) =>
      _participantRoleLabels[role.toUpperCase()] ?? role;

  static Color statusColor(String status, ThemeData theme) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'DONE':
      case 'COMPLETED':
      case 'EVALUATED':
      case 'SCHEDULED':
        return const Color(0xFF059669);
      case 'PROPOSED':
        return const Color(0xFF1E60EC);
      case 'IN_PROGRESS':
        return const Color(0xFF2563EB);
      case 'RESCHEDULE_REQUESTED':
        return const Color(0xFFD97706);
      case 'CANCELLED':
        return theme.colorScheme.error;
      default:
        return const Color(0xFF64748B);
    }
  }

  static String resolveMeetingUrl(String? rawUrl, String? tenantCode) {
    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('/')) {
      final code = (tenantCode != null && tenantCode.isNotEmpty) ? tenantCode : 'portal';
      return 'https://$code.smarthire.top$trimmed';
    }
    return trimmed;
  }
}

