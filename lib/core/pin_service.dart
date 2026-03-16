import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'storage_service.dart';

class PinService {
  static const _pinSaltKey = 'pin_salt';
  static const _pinVerifyKey = 'pin_verify';
  static const _pinEnabledKey = 'pin_enabled';
  static const _pbkdfIterations = 100000;

  static Future<bool> isPinConfigured() async {
    final value = await StorageService.getKey(_pinEnabledKey);
    return value == 'true';
  }

  static Future<void> createPin(String pin) async {
    final salt = _generateSalt();
    final derivedKey = await _deriveKey(pin, salt);

    await _encryptAndStoreKey('identity_private', derivedKey);
    await _encryptAndStoreKey('signing_private', derivedKey);
    await _encryptAndStoreKey('signed_prekey_private_1', derivedKey);

    for (int i = 1; i <= 20; i++) {
      final key = await StorageService.getKey('otpk_private_$i');
      if (key != null) {
        await _encryptAndStoreKey('otpk_private_$i', derivedKey);
      }
    }

    await StorageService.saveKey(_pinSaltKey, base64Encode(salt));

    final verifier = await _encrypt('silex_pin_ok', derivedKey);
    await StorageService.saveKey(_pinVerifyKey, verifier);

    await StorageService.saveKey(_pinEnabledKey, 'true');
  }

  static Future<Map<String, String>?> unlockWithPin(String pin) async {
    final saltB64 = await StorageService.getKey(_pinSaltKey);
    if (saltB64 == null) return null;

    final salt = base64Decode(saltB64);
    final derivedKey = await _deriveKey(pin, salt);

    final verifierEncrypted = await StorageService.getKey(_pinVerifyKey);
    if (verifierEncrypted == null) return null;

    try {
      final verifierPlain = await _decrypt(verifierEncrypted, derivedKey);
      if (verifierPlain != 'silex_pin_ok') return null;
    } catch (_) {
      return null;
    }

    final decryptedKeys = <String, String>{};

    decryptedKeys['identity_private'] =
        await _decryptStoredKey('identity_private', derivedKey);
    decryptedKeys['signing_private'] =
        await _decryptStoredKey('signing_private', derivedKey);
    decryptedKeys['signed_prekey_private_1'] =
        await _decryptStoredKey('signed_prekey_private_1', derivedKey);

    for (int i = 1; i <= 20; i++) {
      final encrypted = await StorageService.getKey('otpk_private_${i}_enc');
      if (encrypted != null) {
        decryptedKeys['otpk_private_$i'] =
            await _decryptStoredKey('otpk_private_$i', derivedKey);
      }
    }

    for (final entry in decryptedKeys.entries) {
      await StorageService.saveKey(entry.key, entry.value);
    }

    return decryptedKeys;
  }

  static List<int> _generateSalt() {
    final random = SecretKeyData.random(length: 16);
    return random.bytes;
  }

  static Future<SecretKey> _deriveKey(String pin, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdfIterations,
      bits: 256,
    );

    return await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
  }

  static Future<String> _encrypt(String plaintext, SecretKey key) async {
    final algorithm = AesGcm.with256bits();
    final nonce = algorithm.newNonce();

    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    final combined = [
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];
    return base64Encode(combined);
  }

  static Future<String> _decrypt(String encrypted, SecretKey key) async {
    final algorithm = AesGcm.with256bits();
    final combined = base64Decode(encrypted);

    final nonce = combined.sublist(0, 12);
    final ciphertext = combined.sublist(12, combined.length - 16);
    final mac = combined.sublist(combined.length - 16);

    final secretBox = SecretBox(
      ciphertext,
      nonce: nonce,
      mac: Mac(mac),
    );

    final plainBytes = await algorithm.decrypt(secretBox, secretKey: key);
    return utf8.decode(plainBytes);
  }

  static Future<void> _encryptAndStoreKey(
      String keyName, SecretKey derivedKey) async {
    final plainValue = await StorageService.getKey(keyName);
    if (plainValue == null) return;

    final encrypted = await _encrypt(plainValue, derivedKey);
    await StorageService.saveKey('${keyName}_enc', encrypted);

    await StorageService.deleteKey(keyName);
  }

  static Future<String> _decryptStoredKey(
      String keyName, SecretKey derivedKey) async {
    final encrypted = await StorageService.getKey('${keyName}_enc');
    if (encrypted == null) throw Exception('Key $keyName not found');
    return await _decrypt(encrypted, derivedKey);
  }
}