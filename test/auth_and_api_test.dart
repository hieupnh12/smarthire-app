import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smarthire_app/core/auth/google_auth_service.dart';
import 'package:smarthire_app/core/constants/api_constants.dart';
import 'package:smarthire_app/core/network/dio_client.dart';
import 'package:smarthire_app/core/storage/storage_service.dart';

class _InMemoryStorageService implements StorageService {
  String? tenantCode = 'se36';
  String? customBaseUrl;
  String? accessToken;
  String? refreshToken;
  Map<String, dynamic>? userData;
  int clearCount = 0;

  @override
  String? getTenantCode() => tenantCode;

  @override
  Future<void> saveTenantCode(String code) async {
    tenantCode = code.trim().toLowerCase();
  }

  @override
  Future<void> clearTenantCode() async {
    tenantCode = null;
  }

  @override
  Map<String, dynamic>? getTenantInfo() => null;

  @override
  Future<void> saveTenantInfo(Map<String, dynamic> info) async {}

  @override
  String? getCustomBaseUrl() => customBaseUrl;

  @override
  Future<void> saveCustomBaseUrl(String url) async {
    customBaseUrl = url.trim();
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    this.accessToken = accessToken;
    if (refreshToken != null) {
      this.refreshToken = refreshToken;
    }
  }

  @override
  Future<void> clearTokens() async {
    clearCount++;
    accessToken = null;
    refreshToken = null;
    userData = null;
  }

  @override
  Map<String, dynamic>? getUserData() => userData;

  @override
  Future<void> saveUserData(Map<String, dynamic> data) async {
    userData = data;
  }
}

void main() {

  group('ApiConstants & DioClient public/auth paths', () {
    test('uses backend /public/jobs path instead of protected /jobs/public', () {
      expect(ApiConstants.publicJobs, equals('/public/jobs'));
      expect(ApiConstants.candidateRefresh, equals('/tenant/auth/refresh'));
    });

    test('classifies public and auth endpoints accurately', () {
      expect(DioClient.isPublicEndpoint('/public/jobs'), isTrue);
      expect(DioClient.isPublicEndpoint('/public/landing'), isTrue);
      expect(DioClient.isPublicEndpoint('/tenant/auth/google'), isTrue);
      expect(DioClient.isPublicEndpoint('/tenant/auth/refresh'), isTrue);
      expect(DioClient.isPublicEndpoint('/master/tenants/check-subdomain/se36'), isTrue);

      expect(DioClient.isPublicEndpoint('/applications/me'), isFalse);
      expect(DioClient.isPublicEndpoint('/tenant/auth/me'), isFalse);
      expect(DioClient.isAuthLifecycleEndpoint('/tenant/auth/logout'), isTrue);
      expect(DioClient.isAuthLifecycleEndpoint('/interviews/mine'), isFalse);
    });
  });

  group('GoogleAuthService error handling', () {
    test('treats plain canceled as user dismissal without error', () {
      const ex = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'activity is cancelled by the user.',
      );
      expect(GoogleAuthService.isUserCancelOnly(ex), isTrue);
    });

    test('surfaces OAuth/SHA-1 error when canceled contains GMS reauth failure details', () {
      const ex = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: '[16] Account reauth failed UNREGISTERED_ON_API_CONSOLE',
      );
      expect(GoogleAuthService.isUserCancelOnly(ex), isFalse);
      expect(
        GoogleAuthService.mapExceptionMessage(ex),
        contains('com.smarthire.smarthire_app'),
      );
    });

    test('maps clientConfigurationError cleanly in Vietnamese', () {
      const ex = GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'Developer console not configured',
      );
      final msg = GoogleAuthService.mapExceptionMessage(ex);
      expect(msg, contains('SHA-1'));
      expect(msg, contains('com.smarthire.smarthire_app'));
    });
  });

  group('DioClient token refresh & session expiry', () {
    test('refreshes expired JWT on 401 and retries protected request', () async {
      final storage = _InMemoryStorageService()
        ..accessToken = 'expired-jwt'
        ..refreshToken = 'valid-refresh';

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      var refreshCalledWithoutAuth = false;
      server.listen((req) async {
        final path = req.uri.path;
        if (path == '/api/v1/applications/me') {
          if (req.headers.value('authorization') == 'Bearer expired-jwt') {
            req.response.statusCode = HttpStatus.unauthorized;
            req.response.headers.contentType = ContentType.json;
            req.response.write(jsonEncode({'success': false, 'code': 'UNAUTHORIZED'}));
          } else if (req.headers.value('authorization') == 'Bearer fresh-jwt') {
            req.response.statusCode = HttpStatus.ok;
            req.response.headers.contentType = ContentType.json;
            req.response.write(jsonEncode({'success': true, 'data': []}));
          } else {
            req.response.statusCode = HttpStatus.unauthorized;
          }
        } else if (path == '/api/v1/tenant/auth/refresh') {
          refreshCalledWithoutAuth = req.headers.value('authorization') == null &&
              req.headers.value('x-tenant-id') == 'se36';
          req.response.statusCode = HttpStatus.ok;
          req.response.headers.contentType = ContentType.json;
          req.response.write(jsonEncode({
            'success': true,
            'data': {
              'accessToken': 'fresh-jwt',
              'refreshToken': 'rotated-refresh',
            },
          }));
        }
        await req.response.close();
      });

      storage.customBaseUrl = 'http://127.0.0.1:${server.port}/api/v1';
      final client = DioClient(storage);
      var expiredCallbacks = 0;
      client.onSessionExpired = () => expiredCallbacks++;

      final res = await client.dio.get('/applications/me');
      expect(res.statusCode, equals(200));
      expect(refreshCalledWithoutAuth, isTrue);
      expect(storage.accessToken, equals('fresh-jwt'));
      expect(storage.refreshToken, equals('rotated-refresh'));
      expect(expiredCallbacks, equals(0));
    });

    test('clears tokens and notifies onSessionExpired when refresh fails', () async {
      final storage = _InMemoryStorageService()
        ..accessToken = 'expired-jwt'
        ..refreshToken = 'dead-refresh';

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((req) async {
        req.response.statusCode = HttpStatus.unauthorized;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'success': false, 'code': 'UNAUTHORIZED'}));
        await req.response.close();
      });

      storage.customBaseUrl = 'http://127.0.0.1:${server.port}/api/v1';
      final client = DioClient(storage);
      var expiredCallbacks = 0;
      client.onSessionExpired = () => expiredCallbacks++;

      await expectLater(client.dio.get('/applications/me'), throwsException);
      expect(storage.clearCount, equals(1));
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(expiredCallbacks, equals(1));
    });
  });
}

