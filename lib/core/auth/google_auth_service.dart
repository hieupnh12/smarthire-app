import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/api_constants.dart';

class GoogleAuthService {
  static const String androidPackageName = 'com.smarthire.smarthire_app';

  bool _isInitialized = false;
  Future<void>? _initFuture;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    if (_initFuture != null) {
      await _initFuture;
      return;
    }

    final future = GoogleSignIn.instance.initialize(
      serverClientId: ApiConstants.googleServerClientId,
    );
    _initFuture = future;
    try {
      await future;
      _isInitialized = true;
    } catch (e) {
      _initFuture = null;
      debugPrint('GoogleSignIn.initialize failed: $e');
      rethrow;
    }
  }

  /// Đăng nhập tài khoản Google và lấy OpenID Connect idToken
  Future<String?> getIdToken() async {
    try {
      await _ensureInitialized();

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile', 'openid'],
      );

      final GoogleSignInAuthentication auth = account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Không lấy được ID Token từ Google. Vui lòng kiểm tra cấu hình Android OAuth Client ID ($androidPackageName) trên Google Cloud Console.',
        );
      }

      return idToken;
    } on GoogleSignInException catch (e) {
      debugPrint(
        'GoogleSignInException: code=${e.code}, description=${e.description}, details=${e.details}',
      );
      if (isUserCancelOnly(e)) {
        return null;
      }
      throw Exception(mapExceptionMessage(e));
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  @visibleForTesting
  static bool isUserCancelOnly(GoogleSignInException exception) {
    if (exception.code != GoogleSignInExceptionCode.canceled) {
      return false;
    }
    final text = '${exception.description ?? ''} ${exception.details ?? ''}'.toLowerCase();
    return !_looksLikeOAuthConfigFailure(text);
  }

  @visibleForTesting
  static String mapExceptionMessage(GoogleSignInException exception) {
    final rawText = '${exception.description ?? ''} ${exception.details ?? ''}'.toLowerCase();
    if (_looksLikeOAuthConfigFailure(rawText) ||
        exception.code == GoogleSignInExceptionCode.clientConfigurationError ||
        exception.code == GoogleSignInExceptionCode.providerConfigurationError) {
      return 'Đăng nhập Google thất bại do ứng dụng Android ($androidPackageName) '
          'chưa khớp OAuth Client / SHA-1 trên Google Cloud Console.';
    }

    switch (exception.code) {
      case GoogleSignInExceptionCode.interrupted:
        return 'Quá trình đăng nhập Google bị gián đoạn. Vui lòng thử lại.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Không thể hiển thị hộp thoại đăng nhập Google trên thiết bị này.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Tài khoản Google được chọn không khớp với phiên đăng nhập hiện tại.';
      case GoogleSignInExceptionCode.unknownError:
        if (rawText.contains('no credential')) {
          return 'Thiết bị chưa sẵn sàng tài khoản Google hoặc ứng dụng chưa được cấp quyền OAuth (kiểm tra tài khoản Google trên máy và SHA-1 trên Google Cloud Console).';
        }
        return 'Không thể đăng nhập bằng Google${exception.description != null && exception.description!.isNotEmpty ? ': ${exception.description}' : '.'}';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
      case GoogleSignInExceptionCode.canceled:
        return 'Đăng nhập Google chưa hoàn tất. Vui lòng thử lại.';
    }
  }

  static bool _looksLikeOAuthConfigFailure(String lowerText) {
    return lowerText.contains('reauth') ||
        lowerText.contains('unregistered') ||
        lowerText.contains('developer') ||
        lowerText.contains('sha-1') ||
        lowerText.contains('sha1') ||
        lowerText.contains('status=10') ||
        lowerText.contains('[10]') ||
        lowerText.contains('[16]') ||
        lowerText.contains('16:');
  }

  /// Đăng xuất tài khoản Google khỏi thiết bị
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out Error: $e');
    }
  }
}
