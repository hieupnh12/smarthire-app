import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/api_constants.dart';

class GoogleAuthService {
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: ApiConstants.googleServerClientId,
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn.initialize warning: $e');
      _isInitialized = true;
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
          'Không lấy được ID Token từ Google. Hãy đảm bảo bạn đã thêm SHA-1 vào Google Cloud Console.',
        );
      }

      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // Người dùng hủy / đóng hộp thoại
        return null;
      }
      debugPrint('GoogleSignInException: ${e.code} - ${e.description}');
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
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
