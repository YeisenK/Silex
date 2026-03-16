import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/crypto_service.dart';
import '../core/storage_service.dart';

class IncomingMessage {
  final String messageId;
  final String senderId;
  final String ciphertext;
  final String iv;
  final String ratchetKey;
  final int prevCounter;
  final int msgCounter;
  final String messageType;
  final String senderIdentityKey;
  final int? usedOtpkId;
  final DateTime receivedAt;
  final String plaintext;

  IncomingMessage({
    required this.messageId,
    required this.senderId,
    required this.ciphertext,
    required this.iv,
    required this.ratchetKey,
    required this.prevCounter,
    required this.msgCounter,
    required this.messageType,
    required this.senderIdentityKey,
    required this.usedOtpkId,
    required this.receivedAt,
    required this.plaintext,
  });

  static IncomingMessage _parseRaw(Map<String, dynamic> map) {
    return IncomingMessage(
      messageId: map['messageId'] as String? ?? map['id'] as String,
      senderId: map['senderId'] as String? ?? map['sender_id'] as String,
      ciphertext: map['ciphertext'] as String,
      iv: map['iv'] as String,
      ratchetKey: map['ratchetKey'] as String? ?? map['ratchet_key'] as String,
      prevCounter: map['prevCounter'] as int? ?? map['prev_counter'] as int,
      msgCounter: map['msgCounter'] as int? ?? map['msg_counter'] as int,
      messageType: map['messageType'] as String? ?? map['message_type'] as String,
      senderIdentityKey: map['senderIdentityKey'] as String? ?? map['sender_identity_key'] as String? ?? '',
      usedOtpkId: map['usedOtpkId'] as int? ?? map['used_otpk_id'] as int?,
      receivedAt: DateTime.now(),
      plaintext: '',
    );
  }

  IncomingMessage copyWithPlaintext(String text) {
    return IncomingMessage(
      messageId: messageId,
      senderId: senderId,
      ciphertext: ciphertext,
      iv: iv,
      ratchetKey: ratchetKey,
      prevCounter: prevCounter,
      msgCounter: msgCounter,
      messageType: messageType,
      senderIdentityKey: senderIdentityKey,
      usedOtpkId: usedOtpkId,
      receivedAt: receivedAt,
      plaintext: text,
    );
  }
}

class MessagesNotifier extends Notifier<List<IncomingMessage>> {
  final Set<String> _readMessageIds = {};

  @override
  List<IncomingMessage> build() => [];

  Future<void> addMessage(Map<String, dynamic> data) async {
    final raw = IncomingMessage._parseRaw(data);
    print('[X3DH-RECV] senderId: ${raw.senderId}');
    print('[X3DH-RECV] senderIdentityKey length: ${raw.senderIdentityKey.length}');
    print('[X3DH-RECV] ratchetKey (ephemeral) length: ${raw.ratchetKey.length}');
    print('[X3DH-RECV] usedOtpkId: ${raw.usedOtpkId}');

    try {
      var sessionKey = await StorageService.getSessionKey(raw.senderId);
      print('[X3DH-RECV] existing sessionKey: ${sessionKey != null}');

      if (sessionKey == null) {
        print('[X3DH-RECV] performing X3DH receiver...');
        sessionKey = await CryptoService.performX3DHReceiver(
          senderIdentityKey: raw.senderIdentityKey,
          ephemeralPublicKey: raw.ratchetKey,
          usedOtpkId: raw.usedOtpkId,
        );
        print('[X3DH-RECV] sessionKey: ${base64Encode(sessionKey)}');
        await StorageService.saveSessionKey(raw.senderId, sessionKey);
      }

      final plaintext = await CryptoService.decryptMessage(
        ciphertext: raw.ciphertext,
        iv: raw.iv,
        sessionKey: sessionKey,
      );
      print('[X3DH-RECV] decrypted: $plaintext');

      state = [...state, raw.copyWithPlaintext(plaintext)];
    } catch (e, stack) {
      print('[X3DH-RECV] ERROR: $e');
      print('[X3DH-RECV] STACK: $stack');
      state = [...state, raw.copyWithPlaintext('[decryption failed]')];
    }
  }

  

    void markAsRead(String senderId) {
      for (final m in state) {
        if (m.senderId == senderId) {
          _readMessageIds.add(m.messageId);
        }
      }
      state = [...state];
    }

    bool isRead(String messageId) => _readMessageIds.contains(messageId);

    void clearMessages() {
      state = [];
      _readMessageIds.clear();
    }

  
}

final messagesProvider =
    NotifierProvider<MessagesNotifier, List<IncomingMessage>>(
  MessagesNotifier.new,
);

class SentMessage {
  final String messageId;
  final String recipientId;
  final String ciphertext;
  final String time;
  final DateTime sentAt;

  SentMessage({
    required this.messageId,
    required this.recipientId,
    required this.ciphertext,
    required this.time,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();
}

class SentMessagesNotifier extends Notifier<List<SentMessage>> {
  @override
  List<SentMessage> build() => [];

  void addMessage(SentMessage message) {
    state = [...state, message];
  }
}

final sentMessagesProvider =
    NotifierProvider<SentMessagesNotifier, List<SentMessage>>(
  SentMessagesNotifier.new,
);