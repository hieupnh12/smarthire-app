import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/json_parsers.dart';
import '../models/application_model.dart';

class ApplicationRepository {
  final DioClient _dioClient;

  ApplicationRepository(this._dioClient);

  Future<List<ApplicationModel>> getMyApplications() async {
    try {
      final response = await _dioClient.dio.get('${ApiConstants.candidateApplications}/me');
      final data = unwrapApiData(response.data);
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(ApplicationModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể tải danh sách ứng tuyển'));
    }
  }

  Future<ApplicationDetailModel> getApplicationDetail(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConstants.candidateApplications}/$id');
      final data = unwrapApiData(response.data);
      if (data is! Map<String, dynamic>) {
        throw Exception('Dữ liệu đơn ứng tuyển không hợp lệ');
      }
      return ApplicationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể tải chi tiết đơn ứng tuyển'));
    }
  }

  Future<CandidateEvaluationModel> getApplicationEvaluation(int id) async {
    try {
      final response =
          await _dioClient.dio.get('${ApiConstants.candidateApplications}/$id/evaluation');
      final data = unwrapApiData(response.data);
      if (data is! Map<String, dynamic>) {
        throw Exception('Dữ liệu đánh giá vòng không hợp lệ');
      }
      return CandidateEvaluationModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể tải kết quả đánh giá các vòng'));
    }
  }

  Future<AssessmentSubmissionDetailModel> getSubmissionDetail(int submissionId) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConstants.candidateSubmissions}/$submissionId/get_submission',
      );
      final data = unwrapApiData(response.data);
      if (data is! Map<String, dynamic>) {
        throw Exception('Dữ liệu bài đánh giá không hợp lệ');
      }
      return AssessmentSubmissionDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể tải chi tiết bài đánh giá'));
    }
  }

  Future<void> withdrawApplication(int applicationId, {String? reason}) async {
    try {
      final trimmed = reason?.trim();
      await _dioClient.dio.post(
        '${ApiConstants.candidateApplications}/$applicationId/withdraw',
        data: (trimmed != null && trimmed.isNotEmpty) ? {'reason': trimmed} : null,
      );
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Rút hồ sơ không thành công'));
    }
  }
}
