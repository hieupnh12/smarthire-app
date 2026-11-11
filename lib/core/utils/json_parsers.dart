import 'package:dio/dio.dart';

/// Shared JSON and HTTP error parsing helpers used across feature models and repositories.
DateTime? parseDateTime(dynamic value) {
  if (value is DateTime) return value.toLocal();
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim())?.toLocal();
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

