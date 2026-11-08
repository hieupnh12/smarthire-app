import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../storage/storage_service.dart';

class DioClient {
  final StorageService _storageService;
  late final Dio dio;

  DioClient(this._storageService) {
    final baseUrl = _storageService.getCustomBaseUrl() ?? ApiConstants.defaultBaseUrl;

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _TenantInterceptor(_storageService),
      _AuthInterceptor(_storageService),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    ]);
  }

  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }
}

class _TenantInterceptor extends Interceptor {
  final StorageService _storage;

  _TenantInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tenantCode = _storage.getTenantCode();
    if (tenantCode != null && tenantCode.isNotEmpty) {
      options.headers[ApiConstants.tenantHeader] = tenantCode;
    }
    super.onRequest(options, handler);
  }
}

class _AuthInterceptor extends QueuedInterceptor {
  final StorageService _storage;

  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConstants.authHeader] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token hết hạn - có thể trigger refresh token hoặc logout
    }
    super.onError(err, handler);
  }
}
