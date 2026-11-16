import 'package:dio/dio.dart';

/// Shared JSON and HTTP error parsing helpers used across feature models and repositories.
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is num) {
    if (value <= 0) return null;
    if (value > 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true).toLocal();
    } else {
      return DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt(), isUtc: true).toLocal();
    }
  }
  if (value is List && value.isNotEmpty) {
    try {
      final y = parseInt(value[0]);
      final m = value.length > 1 ? parseInt(value[1]) : 1;
      final d = value.length > 2 ? parseInt(value[2]) : 1;
      final h = value.length > 3 ? parseInt(value[3]) : 0;
      final min = value.length > 4 ? parseInt(value[4]) : 0;
      final s = value.length > 5 ? parseInt(value[5]) : 0;
      return DateTime.utc(y, m, d, h, min, s).toLocal();
    } catch (_) {}
  }
  if (value is String && value.trim().isNotEmpty) {
    final str = value.trim();
    final numVal = num.tryParse(str);
    if (numVal != null && !str.contains('-') && !str.contains(':')) {
      return parseDateTime(numVal);
    }
    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      return parsed.toLocal();
    }
  }
  return null;
}

double? parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

int parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

List<String> parseStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .where((item) => item != null)
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

dynamic unwrapApiData(dynamic body) {
  if (body is Map<String, dynamic> && body.containsKey('data')) {
    return body['data'];
  }
  return body;
}

String extractDioErrorMessage(DioException error, String fallback) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final msg = data['message'];
    if (msg is String && msg.trim().isNotEmpty) {
      return msg.trim();
    }
  }
  return error.message ?? fallback;
}

