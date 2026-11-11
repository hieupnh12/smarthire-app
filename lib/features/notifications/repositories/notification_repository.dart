import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/json_parsers.dart';
import '../models/notification_models.dart';

class NotificationRepository {
  final DioClient _dioClient;

  NotificationRepository(this._dioClient);

  Future<List<NotificationPreferenceModel>> getPreferences() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.notificationPreferences);
      final data = unwrapApiData(response.data);
      if (data is! List) {
        return NotificationCategoryMeta.normalizePreferences(const []);
      }
      final parsed = data
          .whereType<Map<String, dynamic>>()
          .map(NotificationPreferenceModel.fromJson)
          .toList();
      return NotificationCategoryMeta.normalizePreferences(parsed);
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể tải cấu hình thông báo'));
    }
  }

  Future<List<NotificationPreferenceModel>> updatePreferences(
    List<NotificationPreferenceModel> preferences,
  ) async {
    try {
      final response = await _dioClient.dio.put(
        ApiConstants.notificationPreferences,
        data: preferences.map((item) => item.toJson()).toList(),
      );
      final data = unwrapApiData(response.data);
      if (data is! List) return preferences;
      final parsed = data
          .whereType<Map<String, dynamic>>()
          .map(NotificationPreferenceModel.fromJson)
          .toList();
      return NotificationCategoryMeta.normalizePreferences(parsed);
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể cập nhật cài đặt thông báo'));
    }
  }

  Future<List<NotificationItemModel>> getNotifications({int page = 0}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.notifications,
        queryParameters: {'page': page},
      );
      final data = unwrapApiData(response.data);
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(NotificationItemModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể tải danh sách thông báo'));
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _dioClient.dio.patch(
        '${ApiConstants.notifications}/$id',
        data: {'read': true},
      );
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể đánh dấu đã đọc'));
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dioClient.dio.patch('${ApiConstants.notifications}/read-all');
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể đánh dấu tất cả đã đọc'));
    }
  }
}

