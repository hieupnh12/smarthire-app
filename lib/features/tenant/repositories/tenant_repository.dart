import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/storage_service.dart';
import '../models/tenant_info.dart';

class TenantRepository {
  final DioClient _dioClient;
  final StorageService _storageService;

  TenantRepository(this._dioClient, this._storageService);

  TenantInfo? getCachedTenant() {
    final cachedJson = _storageService.getTenantInfo();
    if (cachedJson != null) {
      return TenantInfo.fromJson(cachedJson);
    }
    final code = _storageService.getTenantCode();
    if (code != null) {
      return TenantInfo(code: code, name: code.toUpperCase());
    }
    return null;
  }

  Future<TenantInfo> lookupTenant(String code) async {
    final normalizedCode = code.trim().toLowerCase();

    try {
      final response = await _dioClient.dio.get(
        ApiConstants.publicLanding,
        options: Options(
          headers: {
            ApiConstants.tenantHeader: normalizedCode,
          },
        ),
      );

      final body = response.data;
      Map<String, dynamic> landingData = {};

      if (body is Map<String, dynamic>) {
        if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
          landingData = body['data'] as Map<String, dynamic>;
        } else {
          landingData = body;
        }
      }

      final tenantInfo = TenantInfo.fromLandingJson(normalizedCode, landingData);

      // Persist to storage
      await _storageService.saveTenantCode(normalizedCode);
      await _storageService.saveTenantInfo(tenantInfo.toJson());

      return tenantInfo;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Mã công ty "$code" không tồn tại trong hệ thống SmartHire.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Doanh nghiệp "$code" hiện chưa được kích hoạt hoặc đang tạm ngưng.');
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối tới máy chủ backend. Vui lòng kiểm tra địa chỉ API hoặc mạng.');
      }
      final message = e.response?.data?['message'] ?? e.message ?? 'Đã có lỗi xảy ra';
      throw Exception('Kiểm tra doanh nghiệp thất bại: $message');
    }
  }

  Future<void> clearTenant() async {
    await _storageService.clearTenantCode();
    await _storageService.clearTokens();
  }
}
