import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/application_model.dart';

class ApplicationRepository {
  final DioClient _dioClient;

  ApplicationRepository(this._dioClient);

  Future<List<ApplicationModel>> getMyApplications() async {
    try {
      final response = await _dioClient.dio.get('${ApiConstants.candidateApplications}/me');
      final body = response.data;
      List<dynamic> items = [];

      if (body is Map<String, dynamic>) {
        if (body['data'] is List) {
          items = body['data'] as List;
        }
      } else if (body is List) {
        items = body;
      }

      return items
          .map((item) => ApplicationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể tải danh sách ứng tuyển';
      throw Exception(msg);
    }
  }

  Future<void> withdrawApplication(int applicationId) async {
    try {
      await _dioClient.dio.post('${ApiConstants.candidateApplications}/$applicationId/withdraw');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Rút hồ sơ không thành công';
      throw Exception(msg);
    }
  }
}
