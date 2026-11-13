import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/json_parsers.dart';
import '../models/mobile_dashboard_model.dart';

class MobileRepository {
  final DioClient _dioClient;

  MobileRepository(this._dioClient);

  Future<MobileConfigModel> getMobileConfig() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.mobileConfig);
      final data = unwrapApiData(response.data);
      if (data is! Map<String, dynamic>) {
        throw Exception('Dữ liệu cấu hình mobile không hợp lệ');
      }
      return MobileConfigModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể tải cấu hình mobile'));
    }
  }

  Future<MobileDashboardModel> getCandidateDashboard() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.mobileDashboard);
      final data = unwrapApiData(response.data);
      if (data is! Map<String, dynamic>) {
        throw Exception('Dữ liệu bảng điều khiển ứng viên không hợp lệ');
      }
      return MobileDashboardModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể tải tổng quan ứng viên'));
    }
  }

  Future<void> registerDeviceToken({
    required String fcmToken,
    String? platform,
    String? deviceModel,
    String? appVersion,
  }) async {
    try {
      final payload = <String, dynamic>{
        'fcmToken': fcmToken,
      };
      if (platform != null) payload['platform'] = platform;
      if (deviceModel != null) payload['deviceModel'] = deviceModel;
      if (appVersion != null) payload['appVersion'] = appVersion;

      await _dioClient.dio.post(
        ApiConstants.mobileDeviceToken,
        data: payload,
      );
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể đăng ký thiết bị nhận thông báo'));
    }
  }
}
