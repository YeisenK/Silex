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

  static Future<Map<String, dynamic>> getMyProfile() async {
    // try local cache first
    final localName = await StorageService.getKey('profile_name');
    final localAvatar = await StorageService.getKey('profile_avatar');

    try {
      final response = await _dio.get(
        '/users/profile/me',
        options: await _authOptions(),
      );
      final data = response.data as Map<String, dynamic>;

      // update local cache with server data
      if (data['displayName'] != null) {
        await StorageService.saveKey('profile_name', data['displayName']);
      }
      if (data['avatarBase64'] != null) {
        await StorageService.saveKey('profile_avatar', data['avatarBase64']);
      }

      // sync pending avatar if exists
      _syncPendingAvatar();

      return data;
    } catch (_) {
      // offline — return local cache
      return {
        'displayName': localName,
        'avatarBase64': localAvatar,
      };
    }
  }

  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final response = await _dio.get(
      '/users/profile/$userId',
      options: await _authOptions(),
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<void> updateDisplayName(String name) async {
    await StorageService.saveKey('profile_name', name);
    try {
      await _dio.put(
        '/users/profile',
        data: {'displayName': name},
        options: await _authOptions(),
      );
    } catch (_) {
      // saved locally, will sync later
    }
  }

  /// Pick image, save locally immediately, upload in background
  static Future<String?> pickImage() async {
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

    // save locally first — instant UI update
    await StorageService.saveKey('profile_avatar', base64String);

    // try upload in background
    _uploadAvatar(base64String);

    return base64String;
  }

  static Future<void> _uploadAvatar(String base64String) async {
    try {
      await _dio.put(
        '/users/profile',
        data: {'avatarBase64': base64String},
        options: await _authOptions(),
      );
      // uploaded — clear pending flag
      await StorageService.deleteKey('profile_avatar_pending');
    } catch (_) {
      // mark as pending for later sync
      await StorageService.saveKey('profile_avatar_pending', 'true');
    }
  }

  /// Call on app startup to sync any pending avatar
  static Future<void> _syncPendingAvatar() async {
    final pending = await StorageService.getKey('profile_avatar_pending');
    if (pending != 'true') return;

    final avatar = await StorageService.getKey('profile_avatar');
    if (avatar == null) return;

    _uploadAvatar(avatar);
  }

  /// Call this on app startup / after unlock
  static Future<void> syncIfNeeded() async {
    _syncPendingAvatar();
  }
}