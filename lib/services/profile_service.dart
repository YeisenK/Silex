import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';

class ProfileService {
  static final _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  static Future<Options> _authOptions() async {
    final token = await StorageService.getJwt();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// Get my own profile
  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _dio.get(
      '/users/profile/me',
      options: await _authOptions(),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get any user's profile
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final response = await _dio.get(
      '/users/profile/$userId',
      options: await _authOptions(),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Update display name
  static Future<void> updateDisplayName(String name) async {
    await _dio.put(
      '/users/profile',
      data: {'displayName': name},
      options: await _authOptions(),
    );
  }

  /// Pick image from gallery, compress, and upload as base64
  static Future<String?> pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 70,
    );

    if (picked == null) return null;

    final bytes = await File(picked.path).readAsBytes();
    final base64String = base64Encode(bytes);

    await _dio.put(
      '/users/profile',
      data: {'avatarBase64': base64String},
      options: await _authOptions(),
    );

    return base64String;
  }

  /// Upload a base64 avatar directly
  static Future<void> updateAvatar(String base64String) async {
    await _dio.put(
      '/users/profile',
      data: {'avatarBase64': base64String},
      options: await _authOptions(),
    );
  }
}
