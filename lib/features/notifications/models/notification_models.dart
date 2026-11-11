import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/json_parsers.dart';

class NotificationPreferenceModel extends Equatable {
  final String category;
  final bool webEnabled;
  final bool emailEnabled;

  const NotificationPreferenceModel({
    required this.category,
    required this.webEnabled,
    required this.emailEnabled,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      category: json['category'] as String? ?? 'APPLICATION',
      webEnabled: json['webEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'webEnabled': webEnabled,
      'emailEnabled': emailEnabled,
    };
  }

  NotificationPreferenceModel copyWith({
    bool? webEnabled,
    bool? emailEnabled,
  }) {
    return NotificationPreferenceModel(
      category: category,
      webEnabled: webEnabled ?? this.webEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }

  @override
  List<Object?> get props => [category, webEnabled, emailEnabled];
}

class NotificationItemModel extends Equatable {
  final int id;
  final String type;
  final String title;
  final String? body;
  final String? payloadJson;
  final DateTime? readAt;
  final DateTime? createdAt;

  const NotificationItemModel({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.payloadJson,
    this.readAt,
    this.createdAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: parseInt(json['id']),
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? 'Thông báo',
      body: json['body'] as String?,
      payloadJson: json['payloadJson'] as String?,
      readAt: parseDateTime(json['readAt']),
      createdAt: parseDateTime(json['createdAt']),
    );
  }

  bool get isRead => readAt != null;

  String? extractPath() {
    final raw = payloadJson;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final path = decoded['path'];
        if (path is String && path.trim().isNotEmpty) {
          return path.replaceFirst(RegExp(r'^/candidate(?=/)'), '');
        }
      }
    } catch (_) {}
    return null;
  }

  NotificationItemModel markReadLocally() {
    return NotificationItemModel(
      id: id,
      type: type,
      title: title,
      body: body,
      payloadJson: payloadJson,
      readAt: readAt ?? DateTime.now(),
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, payloadJson, readAt, createdAt];
}

class NotificationCategoryMeta {
  final String key;
  final String label;
  final String description;
  final IconData icon;

  const NotificationCategoryMeta({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
  });

  static const List<NotificationCategoryMeta> candidateCategories = [
    NotificationCategoryMeta(
      key: 'APPLICATION',
      label: 'Kết quả hồ sơ',
      description: 'Thông báo khi có cập nhật trạng thái hoặc kết quả hồ sơ ứng tuyển.',
      icon: Icons.description_outlined,
    ),
    NotificationCategoryMeta(
      key: 'AI_INTERVIEW',
      label: 'Phỏng vấn AI',
      description: 'Lời mời, lượt làm lại và kết quả phỏng vấn AI.',
      icon: Icons.smart_toy_outlined,
    ),
    NotificationCategoryMeta(
      key: 'ASSESSMENT',
      label: 'Bài đánh giá',
      description: 'Lời mời làm bài kiểm tra năng lực và kết quả chấm điểm.',
      icon: Icons.assignment_turned_in_outlined,
    ),
    NotificationCategoryMeta(
      key: 'HUMAN_INTERVIEW',
      label: 'Phỏng vấn trực tiếp',
      description: 'Lịch hẹn, nhắc lịch và cập nhật lịch phỏng vấn với nhà tuyển dụng.',
      icon: Icons.event_available_outlined,
    ),
  ];

  static List<NotificationPreferenceModel> normalizePreferences(
    List<NotificationPreferenceModel> serverPrefs,
  ) {
    final byKey = {for (final p in serverPrefs) p.category: p};
    return candidateCategories
        .map(
          (meta) =>
              byKey[meta.key] ??
              NotificationPreferenceModel(
                category: meta.key,
                webEnabled: true,
                emailEnabled: true,
              ),
        )
        .toList();
  }
}

