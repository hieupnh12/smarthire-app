import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  static const String _keyTenantCode = 'active_tenant_code';
  static const String _keyTenantInfo = 'active_tenant_info';
  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyAccessToken = 'jwt_access_token';
  static const String _keyRefreshToken = 'jwt_refresh_token';
  static const String _keyUserData = 'current_user_data';

  StorageService(this._prefs, this._secureStorage);

  // Tenant Code
  String? getTenantCode() {
    return _prefs.getString(_keyTenantCode);
  }

  Future<void> saveTenantCode(String code) async {
    await _prefs.setString(_keyTenantCode, code.trim().toLowerCase());
  }

  Future<void> clearTenantCode() async {
    await _prefs.remove(_keyTenantCode);
    await _prefs.remove(_keyTenantInfo);
  }

  // Tenant Info Json Cache
  Map<String, dynamic>? getTenantInfo() {
    final raw = _prefs.getString(_keyTenantInfo);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTenantInfo(Map<String, dynamic> info) async {
    await _prefs.setString(_keyTenantInfo, jsonEncode(info));
  }

  // Custom Base URL (nếu người dùng muốn đổi IP local để test)
  String? getCustomBaseUrl() {
    return _prefs.getString(_keyBaseUrl);
  }

  Future<void> saveCustomBaseUrl(String url) async {
    await _prefs.setString(_keyBaseUrl, url.trim());
  }

  // Auth Tokens (Secure Storage)
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _prefs.remove(_keyUserData);
  }

  // Cached User Profile
  Map<String, dynamic>? getUserData() {
    final raw = _prefs.getString(_keyUserData);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserData(Map<String, dynamic> data) async {
    await _prefs.setString(_keyUserData, jsonEncode(data));
  }
}
