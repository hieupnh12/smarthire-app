import 'package:dio/dio.dart';
import '../../../core/auth/google_auth_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient _dioClient;
  final StorageService _storageService;
  final GoogleAuthService _googleAuthService;

  AuthRepository(
    this._dioClient,
    this._storageService,
    this._googleAuthService,
  );

  UserModel? getCachedUser() {
    final cached = _storageService.getUserData();
    if (cached != null) {
      return UserModel.fromJson(cached);
    }
    return null;
  }

  /// Đăng nhập duy nhất bằng tài khoản Google (Lấy idToken và gửi lên backend)
  Future<UserModel?> loginWithGoogle() async {
    final idToken = await _googleAuthService.getIdToken();

    if (idToken == null) {
      // Người dùng hủy hộp thoại Google
      return null;
    }

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.candidateGoogleLogin,
        data: {
          'idToken': idToken,
        },
      );

      return await _processAuthResponse(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final serverMessage = data is Map<String, dynamic> ? data['message'] as String? : null;
      final msg = serverMessage ?? e.message ?? 'Xác thực tài khoản Google thất bại';
      throw Exception(msg);
    }
  }

  Future<UserModel> _processAuthResponse(dynamic responseBody) async {
    Map<String, dynamic> data = {};
    if (responseBody is Map<String, dynamic>) {
      final inner = responseBody['data'];
      data = inner is Map<String, dynamic> ? inner : responseBody;
    }

    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Không nhận được mã xác thực token từ máy chủ.');
    }

    await _storageService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final rawUser = data['candidate'] ?? data['user'] ?? data;
    if (rawUser is! Map<String, dynamic>) {
      throw Exception('Dữ liệu hồ sơ ứng viên từ máy chủ không hợp lệ.');
    }
    final user = UserModel.fromJson(rawUser);
    await _storageService.saveUserData(user.toJson());

    return user;
  }

  Future<void> logout() async {
    try {
      await _dioClient.dio.post(ApiConstants.candidateLogout);
    } catch (_) {}

    await _googleAuthService.signOut();
    await _storageService.clearTokens();
  }

  Future<UserModel?> checkCurrentUser() async {
    final token = await _storageService.getAccessToken();
    final refreshToken = await _storageService.getRefreshToken();
    final hasAccess = token != null && token.isNotEmpty;
    final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;
    if (!hasAccess && !hasRefresh) return null;

    final cached = getCachedUser();

    try {
      final response = await _dioClient.dio.get(ApiConstants.candidateProfile);
      final body = response.data;
      Map<String, dynamic> data = {};
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        data = inner is Map<String, dynamic> ? inner : body;
      }
      final user = UserModel.fromJson(data);
      await _storageService.saveUserData(user.toJson());
      return user;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403 || status == 404) {
        await _storageService.clearTokens();
        return null;
      }
      // Giữ trạng thái đăng nhập tạm thời nếu chỉ mất kết nối mạng lúc khởi động
      if (cached != null) return cached;
      return null;
    } catch (_) {
      return cached;
    }
  }
}
