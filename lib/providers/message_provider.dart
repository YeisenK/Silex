import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomingMessage {
  final String messageId;
  final String senderId;
  final String ciphertext;
  final String iv;
  final String ratchetKey;
  final int prevCounter;
  final int msgCounter;
  final String messageType;
  final DateTime receivedAt;

  IncomingMessage({
    required this.messageId,
    required this.senderId,
    required this.ciphertext,
    required this.iv,
    required this.ratchetKey,
    required this.prevCounter,
    required this.msgCounter,
    required this.messageType,
    required this.receivedAt,
  });

  factory IncomingMessage.fromMap(Map<String, dynamic> map) {
    return IncomingMessage(
      messageId: map['messageId'] as String,
      senderId: map['senderId'] as String? ?? map['sender_id'] as String,
      ciphertext: map['ciphertext'] as String,
      iv: map['iv'] as String,
      ratchetKey: map['ratchetKey'] as String? ?? map['ratchet_key'] as String,
      prevCounter: map['prevCounter'] as int? ?? map['prev_counter'] as int,
      msgCounter: map['msgCounter'] as int? ?? map['msg_counter'] as int,
      messageType: map['messageType'] as String? ?? map['message_type'] as String,
      receivedAt: DateTime.now(),
    );
  }
}

class MessagesNotifier extends Notifier<List<IncomingMessage>> {
  @override
  List<IncomingMessage> build() => [];

  void addMessage(Map<String, dynamic> data) {
    final message = IncomingMessage.fromMap(data);
    state = [...state, message];
  }

  void clearMessages() {
    state = [];
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

  SentMessage({
    required this.messageId,
    required this.recipientId,
    required this.ciphertext,
    required this.time,
  });
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