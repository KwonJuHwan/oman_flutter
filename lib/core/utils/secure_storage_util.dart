import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageUtil {
  static const _storage = FlutterSecureStorage();
  
  static const _keyAccessToken = 'accessToken';
  static const _keyRefreshToken = 'refreshToken';

  // 토큰 저장
  static Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _keyAccessToken, value: access);
    await _storage.write(key: _keyRefreshToken, value: refresh);
  }

  // Access Token 읽기
  static Future<String?> getAccessToken() async => await _storage.read(key: _keyAccessToken);
  
  // Refresh Token 읽기
  static Future<String?> getRefreshToken() async => await _storage.read(key: _keyRefreshToken);

  // 로그아웃 시 토큰 전체 삭제
  static Future<void> clearTokens() async => await _storage.deleteAll();
}