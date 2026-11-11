import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../storage/storage_service.dart';

class DioClient {
  final StorageService _storageService;
  late final Dio dio;
  VoidCallback? onSessionExpired;
  Future<_RefreshOutcome>? _refreshInFlight;

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
      _AuthInterceptor(this, _storageService),
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

  @visibleForTesting
  static bool isPublicEndpoint(String path) {
    final normalized = _normalizePath(path);
    return normalized == ApiConstants.candidateGoogleLogin ||
        normalized == ApiConstants.candidateRefresh ||
        normalized == '/tenant/auth/login' ||
        normalized.startsWith('/public/') ||
        normalized.startsWith('/master/tenants/');
  }

  @visibleForTesting
  static bool isAuthLifecycleEndpoint(String path) {
    final normalized = _normalizePath(path);
    return isPublicEndpoint(normalized) ||
        normalized == ApiConstants.candidateLogout;
  }

  static String _normalizePath(String path) {
    final withoutQuery = path.split('?').first;
    final apiPrefixIdx = withoutQuery.indexOf('/api/v1');
    if (apiPrefixIdx >= 0) {
      return withoutQuery.substring(apiPrefixIdx + '/api/v1'.length);
    }
    return withoutQuery;
  }

  Future<_RefreshOutcome> _refreshAccessToken() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final future = _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
    _refreshInFlight = future;
    return future;
  }

  Future<_RefreshOutcome> _performRefresh() async {
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return const _RefreshOutcome.invalidSession();
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    final tenantCode = _storageService.getTenantCode();
    if (tenantCode != null && tenantCode.isNotEmpty) {
      refreshDio.options.headers[ApiConstants.tenantHeader] = tenantCode;
    }

    try {
      final response = await refreshDio.post(
        ApiConstants.candidateRefresh,
        data: {'refreshToken': refreshToken},
      );
      final body = response.data;
      Map<String, dynamic> data = {};
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        data = inner is Map<String, dynamic> ? inner : body;
      }
      final newAccess = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (newAccess == null || newAccess.isEmpty) {
        return const _RefreshOutcome.invalidSession();
      }
      await _storageService.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return _RefreshOutcome.refreshed(newAccess);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403 || status == 404) {
        return const _RefreshOutcome.invalidSession();
      }
      return const _RefreshOutcome.transientFailure();
    } catch (_) {
      return const _RefreshOutcome.transientFailure();
    }
  }
}

class _RefreshOutcome {
  final String? accessToken;
  final bool shouldClearSession;

  const _RefreshOutcome.refreshed(String token)
      : accessToken = token,
        shouldClearSession = false;

  const _RefreshOutcome.invalidSession()
      : accessToken = null,
        shouldClearSession = true;

  const _RefreshOutcome.transientFailure()
      : accessToken = null,
        shouldClearSession = false;
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

class _AuthInterceptor extends Interceptor {
  final DioClient _client;
  final StorageService _storage;

  _AuthInterceptor(this._client, this._storage);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!DioClient.isPublicEndpoint(options.path)) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers[ApiConstants.authHeader] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final options = err.requestOptions;

    if (status == 401 &&
        options.extra['_authRetried'] != true &&
        !DioClient.isAuthLifecycleEndpoint(options.path)) {
      final hadAccess = (await _storage.getAccessToken())?.isNotEmpty == true;
      final hadRefresh = (await _storage.getRefreshToken())?.isNotEmpty == true;

      if (hadAccess || hadRefresh) {
        final outcome = await _client._refreshAccessToken();
        if (outcome.accessToken != null) {
          options.extra['_authRetried'] = true;
          options.headers[ApiConstants.authHeader] = 'Bearer ${outcome.accessToken}';
          try {
            final response = await _client.dio.fetch<dynamic>(options);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        } else if (outcome.shouldClearSession) {
          await _storage.clearTokens();
          _client.onSessionExpired?.call();
        }
      }
    }

    handler.next(err);
  }
}
