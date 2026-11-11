import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/json_parsers.dart';
import '../models/human_interview_model.dart';

class InterviewRepository {
  final DioClient _dioClient;

  InterviewRepository(this._dioClient);

  Future<List<HumanInterviewModel>> getMyInterviews() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.candidateMyInterviews);
      final data = unwrapApiData(response.data);
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(HumanInterviewModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể tải lịch phỏng vấn'));
    }
  }

  Future<HumanInterviewModel> getInterviewDetail(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConstants.candidateInterviews}/$id');
      final data = unwrapApiData(response.data);
      if (data is! Map<String, dynamic>) {
        throw Exception('Dữ liệu phỏng vấn không hợp lệ');
      }
      return HumanInterviewModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể tải chi tiết phỏng vấn'));
    }
  }

  Future<HumanInterviewModel> confirmInterview(int id) async {
    try {
      final response = await _dioClient.dio.post('${ApiConstants.candidateInterviews}/$id/confirm');
      final data = unwrapApiData(response.data);
      if (data is! Map<String, dynamic>) {
        throw Exception('Phản hồi xác nhận không hợp lệ');
      }
      return HumanInterviewModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể xác nhận lịch phỏng vấn'));
    }
  }

  Future<HumanInterviewModel> requestReschedule({
    required int id,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.candidateInterviews}/$id/reschedule-request',
        data: {
          'start': start.toUtc().toIso8601String(),
          'end': end.toUtc().toIso8601String(),
          'reason': reason.trim(),
        },
      );
      final data = unwrapApiData(response.data);
      if (data is! Map<String, dynamic>) {
        throw Exception('Phản hồi đổi lịch không hợp lệ');
      }
      return HumanInterviewModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(extractDioErrorMessage(e, 'Không thể gửi đề nghị đổi lịch'));
    }
  }
}

