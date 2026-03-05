import 'package:dio/dio.dart';
import '../utils/secure_storage_util.dart';
import '../config/api_constants.dart';
import '/main.dart';

class TokenInterceptor extends Interceptor {
  final Dio dio;

  TokenInterceptor(this.dio);


  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {

    final accessToken = await SecureStorageUtil.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return super.onRequest(options, handler);
  }


  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {

    if (err.response?.statusCode == 401) {
      final refreshToken = await SecureStorageUtil.getRefreshToken();
      
      if (refreshToken == null) {
     
        return handler.next(err);
      }

      try {

        final refreshDio = Dio(); 
        final refreshResponse = await refreshDio.post(
          ApiConstants.refreshToken,
          data: {'refreshToken': refreshToken},
        );

        if (refreshResponse.statusCode == 200) {
          final newAccessToken = refreshResponse.data['accessToken'];
          final newRefreshToken = refreshResponse.data['refreshToken'];
          await SecureStorageUtil.saveTokens(access: newAccessToken, refresh: newRefreshToken);

          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        }
      } catch (e) {
        await SecureStorageUtil.clearTokens();
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login', 
          (route) => false, 
        );
      }
    }
    
    return handler.next(err);
  }
}