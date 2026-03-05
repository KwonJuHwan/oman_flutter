import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_constants.dart';
import 'package:oman_fe/core/utils/secure_storage_util.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: ApiConstants.googleServerClientId,
    scopes: ['email', 'profile'],
  );

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        return await _sendTokenToBackend('google', idToken);
      }
      return false;
    } catch (e) {
      print('구글 로그인 중 에러 발생: $e');
      return false;
    }
  }

  Future<bool> _sendTokenToBackend(String provider, String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/login/$provider'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String accessToken = data['accessToken'];
        final String refreshToken = data['refreshToken'];

        await SecureStorageUtil.saveTokens(
        access: accessToken,
        refresh: refreshToken,
      );
        
        return true;
      } else {
        print('백엔드 인증 실패: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('백엔드 통신 에러: $e');
      return false;
    }
  }

  // 로그아웃 시 필요
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}