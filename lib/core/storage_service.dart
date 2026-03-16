import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const _keyJwt = 'jwt_token';
  static const _keyUserId = 'user_id';

  // JWT
  static Future<void> saveJwt(String token) =>
      _storage.write(key: _keyJwt, value: token);

  static Future<String?> getJwt() =>
      _storage.read(key: _keyJwt);

  static Future<void> deleteJwt() =>
      _storage.delete(key: _keyJwt);

  // User ID
  static Future<void> saveUserId(String userId) =>
      _storage.write(key: _keyUserId, value: userId);

  static Future<String?> getUserId() =>
      _storage.read(key: _keyUserId);

  static Future<void> deleteUserId() =>
      _storage.delete(key: _keyUserId);

  // Clear
  static Future<void> clearAll() => _storage.deleteAll();

  //private and public keys
  static Future<void> saveKey(String name, String value) =>
      _storage.write(key: 'key_$name', value: value);

  static Future<String?> getKey(String name) =>
      _storage.read(key: 'key_$name');

  static Future<void> deleteKey(String name) =>
      _storage.delete(key: 'key_$name');

// Session keys per user
  static Future<void> saveSessionKey(String userId, List<int> keyBytes) =>
      _storage.write(key: 'session_$userId', value: base64Encode(keyBytes));

  static Future<List<int>?> getSessionKey(String userId) async {
    final value = await _storage.read(key: 'session_$userId');
    if (value == null) return null;
    return base64Decode(value);
  }

  static Future<void> clearSessionKeys() async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      if (key.startsWith('session_')) {
        await _storage.delete(key: key);
      }
    }
  }

}