import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'storage_service.dart';

class CryptoService {
  static final _ed25519 = Ed25519();
  static final _x25519 = X25519();

  static Future<String> generateIdentityKey() async {
    final keyPair = await _x25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKey = await keyPair.extractPrivateKeyBytes();

    await StorageService.saveKey('identity_private', base64Encode(privateKey));
    await StorageService.saveKey('identity_public', base64Encode(publicKey.bytes));

    final signingPair = await _ed25519.newKeyPair();
    final signingPrivate = await signingPair.extractPrivateKeyBytes();
    await StorageService.saveKey('signing_private', base64Encode(signingPrivate));

    return base64Encode(publicKey.bytes);
  }

  static Future<Map<String, dynamic>> generateSignedPrekey(int id) async {
    final keyPair = await _x25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKey = await keyPair.extractPrivateKeyBytes();

    final signingPrivateBytes = base64Decode(
      (await StorageService.getKey('signing_private'))!,
    );
    final signingKeyPair = await _ed25519.newKeyPairFromSeed(signingPrivateBytes);

    final signature = await _ed25519.sign(
      publicKey.bytes,
      keyPair: signingKeyPair,
    );

    await StorageService.saveKey(
      'signed_prekey_private_$id',
      base64Encode(privateKey),
    );

    return {
      'id': id,
      'publicKey': base64Encode(publicKey.bytes),
      'signature': base64Encode(signature.bytes),
    };
  }

  static Future<List<Map<String, dynamic>>> generateOneTimePrekeys({
    int count = 20,
    int startId = 1,
  }) async {
    final prekeys = <Map<String, dynamic>>[];

    for (int i = 0; i < count; i++) {
      final id = startId + i;
      final keyPair = await _x25519.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final privateKey = await keyPair.extractPrivateKeyBytes();

      await StorageService.saveKey(
        'otpk_private_$id',
        base64Encode(privateKey),
      );

      prekeys.add({
        'id': id,
        'key': base64Encode(publicKey.bytes),
      });
    }

    return prekeys;
  }

  static Future<Map<String, dynamic>> generateAllKeys() async {
    final identityKey = await generateIdentityKey();
    final signedPrekey = await generateSignedPrekey(1);
    final oneTimePrekeys = await generateOneTimePrekeys();

    await StorageService.saveKey('keys_generated', 'true');

    return {
      'identityKey': identityKey,
      'signedPrekey': signedPrekey['publicKey'],
      'signedPrekeySignature': signedPrekey['signature'],
      'signedPrekeyId': signedPrekey['id'],
      'oneTimePrekeys': oneTimePrekeys,
    };
  }

  static Future<bool> keysGenerated() async {
    final value = await StorageService.getKey('keys_generated');
    return value == 'true';
  }

  static Future<void> ensureIdentityPublic() async {
    final existing = await StorageService.getKey('identity_public');
    if (existing != null) return;

    final privateBytes = base64Decode(
      (await StorageService.getKey('identity_private'))!,
    );
    final keyPair = await _x25519.newKeyPairFromSeed(privateBytes);
    final publicKey = await keyPair.extractPublicKey();
    await StorageService.saveKey('identity_public', base64Encode(publicKey.bytes));
  }

  static Future<Map<String, String>> encryptMessage({
    required String plaintext,
    required List<int> sessionKey,
  }) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKeyFromBytes(sessionKey);
    final nonce = algorithm.newNonce();

    final secretBox = await algorithm.encrypt(
      plaintext.codeUnits,
      secretKey: secretKey,
      nonce: nonce,
    );

    return {
      'ciphertext': base64Encode(secretBox.cipherText + secretBox.mac.bytes),
      'iv': base64Encode(nonce),
    };
  }

  static Future<String> decryptMessage({
    required String ciphertext,
    required String iv,
    required List<int> sessionKey,
  }) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKeyFromBytes(sessionKey);

    final ciphertextBytes = base64Decode(ciphertext);
    final macBytes = ciphertextBytes.sublist(ciphertextBytes.length - 16);
    final messageBytes = ciphertextBytes.sublist(0, ciphertextBytes.length - 16);

    final secretBox = SecretBox(
      messageBytes,
      nonce: base64Decode(iv),
      mac: Mac(macBytes),
    );

    final plaintext = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return String.fromCharCodes(plaintext);
  }

  static Future<Map<String, dynamic>> performX3DH({
    required Map<String, dynamic> recipientKeyBundle,
  }) async {
    final ekPair = await _x25519.newKeyPair();
    final ekPublic = await ekPair.extractPublicKey();

    final ikPrivateBytes = base64Decode(
      (await StorageService.getKey('identity_private'))!,
    );
    final ikPair = await _x25519.newKeyPairFromSeed(ikPrivateBytes);

    final ikBPublic = SimplePublicKey(
      base64Decode(recipientKeyBundle['identity_key'] as String),
      type: KeyPairType.x25519,
    );
    final spkBPublic = SimplePublicKey(
      base64Decode(recipientKeyBundle['signed_prekey'] as String),
      type: KeyPairType.x25519,
    );

    final dh1 = await _x25519.sharedSecretKey(
      keyPair: ikPair,
      remotePublicKey: spkBPublic,
    );
    final dh2 = await _x25519.sharedSecretKey(
      keyPair: ekPair,
      remotePublicKey: ikBPublic,
    );
    final dh3 = await _x25519.sharedSecretKey(
      keyPair: ekPair,
      remotePublicKey: spkBPublic,
    );

    final dh1Bytes = await dh1.extractBytes();
    final dh2Bytes = await dh2.extractBytes();
    final dh3Bytes = await dh3.extractBytes();

    List<int> dhConcat = [...dh1Bytes, ...dh2Bytes, ...dh3Bytes];

    if (recipientKeyBundle['one_time_prekey'] != null) {
      final otpkPublic = SimplePublicKey(
        base64Decode(
          (recipientKeyBundle['one_time_prekey'] as Map)['key'] as String,
        ),
        type: KeyPairType.x25519,
      );
      final dh4 = await _x25519.sharedSecretKey(
        keyPair: ekPair,
        remotePublicKey: otpkPublic,
      );
      dhConcat = [...dhConcat, ...await dh4.extractBytes()];
    }

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final sessionKey = await hkdf.deriveKey(
      secretKey: SecretKey(dhConcat),
      nonce: utf8.encode('silex-x3dh-v1'),
    );

    return {
      'sessionKey': await sessionKey.extractBytes(),
      'ephemeralPublicKey': base64Encode(ekPublic.bytes),
    };
  }

  static Future<List<int>> performX3DHReceiver({
    required String senderIdentityKey,
    required String ephemeralPublicKey,
    int? usedOtpkId,
  }) async {
    final ikPrivateBytes = base64Decode(
      (await StorageService.getKey('identity_private'))!,
    );
    final ikPair = await _x25519.newKeyPairFromSeed(ikPrivateBytes);

    final spkPrivateBytes = base64Decode(
      (await StorageService.getKey('signed_prekey_private_1'))!,
    );
    final spkPair = await _x25519.newKeyPairFromSeed(spkPrivateBytes);

    final ikAPublic = SimplePublicKey(
      base64Decode(senderIdentityKey),
      type: KeyPairType.x25519,
    );
    final ekAPublic = SimplePublicKey(
      base64Decode(ephemeralPublicKey),
      type: KeyPairType.x25519,
    );

    final dh1 = await _x25519.sharedSecretKey(
      keyPair: spkPair,
      remotePublicKey: ikAPublic,
    );
    final dh2 = await _x25519.sharedSecretKey(
      keyPair: ikPair,
      remotePublicKey: ekAPublic,
    );
    final dh3 = await _x25519.sharedSecretKey(
      keyPair: spkPair,
      remotePublicKey: ekAPublic,
    );

    final dh1Bytes = await dh1.extractBytes();
    final dh2Bytes = await dh2.extractBytes();
    final dh3Bytes = await dh3.extractBytes();

    List<int> dhConcat = [...dh1Bytes, ...dh2Bytes, ...dh3Bytes];

    if (usedOtpkId != null) {
      final otpkPrivateBytes = base64Decode(
        (await StorageService.getKey('otpk_private_$usedOtpkId'))!,
      );
      final otpkPair = await _x25519.newKeyPairFromSeed(otpkPrivateBytes);
      final dh4 = await _x25519.sharedSecretKey(
        keyPair: otpkPair,
        remotePublicKey: ekAPublic,
      );
      dhConcat = [...dhConcat, ...await dh4.extractBytes()];
    }

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final sessionKey = await hkdf.deriveKey(
      secretKey: SecretKey(dhConcat),
      nonce: utf8.encode('silex-x3dh-v1'),
    );

    return await sessionKey.extractBytes();
  }
}