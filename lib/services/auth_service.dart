import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';

class AuthService {
  static final _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  /// POST /auth/request-otp
  static Future<String?> requestOtp(String phone) async {
    final response = await _dio.post('/auth/request-otp', data: {'phone': phone});
    return response.data['otp'] as String?;
  }

  /// POST /auth/verify-otp
  static Future<void> verifyOtp(String phone, String code) async {
    final response = await _dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'code': code,
    });

    final token = response.data['accessToken'] as String;
    final userId = response.data['userId'] as String;

    await StorageService.saveJwt(token);
    await StorageService.saveUserId(userId);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await StorageService.getJwt();
    return token != null;
  }

  /// Logout
  static Future<void> logout() async {
    await StorageService.clearAll();
  }
}