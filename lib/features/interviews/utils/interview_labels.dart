import 'package:flutter/material.dart';

class InterviewLabels {
  InterviewLabels._();

  static const Map<String, String> _roundLabels = {
    'TECHNICAL': 'Vòng 1: Kỹ thuật chuyên sâu',
    'CULTURE': 'Vòng 2: Culture & Leadership',
    'EXECUTIVE': 'Vòng 3: Ban Giám Đốc',
  };

  static const Map<String, String> _statusLabels = {
    'DRAFT': 'Bản nháp',
    'PROPOSED': 'Chờ xác nhận',
    'CONFIRMED': 'Đã xác nhận',
    'RESCHEDULE_REQUESTED': 'Đề nghị đổi giờ',
    'CANCELLED': 'Đã hủy',
    'DONE': 'Hoàn thành',
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
        return Colors.green.shade700;
      case 'PROPOSED':
        return theme.colorScheme.primary;
      case 'RESCHEDULE_REQUESTED':
        return Colors.orange.shade800;
      case 'CANCELLED':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.secondary;
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

