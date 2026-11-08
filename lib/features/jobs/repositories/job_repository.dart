import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/job_model.dart';

class JobRepository {
  final DioClient _dioClient;

  JobRepository(this._dioClient);

  Future<List<JobModel>> getPublicJobs({String? search}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.publicJobs,
        queryParameters: search != null && search.isNotEmpty ? {'q': search} : null,
      );

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
          .map((item) => JobModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể tải danh sách việc làm';
      throw Exception(msg);
    }
  }

  Future<JobModel> getJobDetail(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConstants.publicJobs}/$id');
      final body = response.data;
      Map<String, dynamic> data = {};
      if (body is Map<String, dynamic>) {
        data = body['data'] as Map<String, dynamic>? ?? body;
      }
      return JobModel.fromJson(data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể tải chi tiết công việc';
      throw Exception(msg);
    }
  }

  Future<void> applyJob({required int jobId, String? coverNote, int? cvId}) async {
    final payload = <String, dynamic>{};
    if (cvId != null) payload['cvId'] = cvId;
    if (coverNote != null) payload['coverNote'] = coverNote;

    try {
      await _dioClient.dio.post(
        '/jobs/$jobId/applications',
        data: payload,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Nộp đơn ứng tuyển không thành công';
      throw Exception(msg);
    }
  }
}
