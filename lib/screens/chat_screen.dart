import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:silex/core/crypto_service.dart';
import 'package:silex/models/message.dart';
import 'package:silex/services/keys_service.dart';
import 'package:silex/services/message_service.dart' hide SentMessage;
import 'package:silex/theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/user_avatar.dart';
import '../models/chat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/message_provider.dart';
import '../core/storage_service.dart';
import 'safety_number_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Chat chat;
  const ChatScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const Color backgroundColor = AppTheme.backgroundPrimary;
  static const Color secondaryBackground = AppTheme.backgroundSecondary;
  static const Color inputColor = Color(0xFF1F3A44);
  static const Color accentColor = AppTheme.accentColor;
  static const Color textPrimary = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;

  Future<void> _sendMessage(String text) async {
    try {
      var sessionKey = await StorageService.getSessionKey(widget.chat.id);
      String? ephemeralKey;
      int? usedOtpkId;

      if (sessionKey == null) {
        final keyBundle = await KeysService.getKeyBundle(widget.chat.id);
        final x3dhResult = await CryptoService.performX3DH(
          recipientKeyBundle: keyBundle,
        );
        sessionKey = x3dhResult['sessionKey'] as List<int>;
        ephemeralKey = x3dhResult['ephemeralPublicKey'] as String;
        usedOtpkId = keyBundle['one_time_prekey']?['id'] as int?;
        await StorageService.saveSessionKey(widget.chat.id, sessionKey);
      }

      final identityKey = (await StorageService.getKey('identity_public'))!;

      final encrypted = await CryptoService.encryptMessage(
        plaintext: text,
        sessionKey: sessionKey,
      );

      await MessageService.sendMessage(
        recipientId: widget.chat.id,
        ratchetKey: ephemeralKey ?? identityKey,
        prevCounter: 0,
        msgCounter: 0,
        ciphertext: encrypted['ciphertext']!,
        iv: encrypted['iv']!,
        senderIdentityKey: identityKey,
        usedOtpkId: usedOtpkId,
      );

      ref.read(sentMessagesProvider.notifier).addMessage(
        SentMessage(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          recipientId: widget.chat.id,
          ciphertext: text,
          time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        ),
      );

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: secondaryBackground,
        iconTheme: const IconThemeData(color: textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                UserAvatar(
                  avatarPath: widget.chat.avatar,
                  name: widget.chat.name,
                ),
                if (widget.chat.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: secondaryBackground,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.name,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.chat.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.chat.isOnline ? accentColor : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const Icon(Icons.call, color: textPrimary),
          const SizedBox(width: 12),
          const Icon(Icons.search, color: textPrimary),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: textPrimary),
            color: secondaryBackground,
            onSelected: (value) {
              if (value == 'verify') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SafetyNumberScreen(
                      contactId: widget.chat.id,
                      contactName: widget.chat.name,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'verify',
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined,
                        color: AppTheme.textSecondary, size: 20),
                    SizedBox(width: 12),
                    Text('Verify identity',
                        style: TextStyle(color: AppTheme.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [backgroundColor, secondaryBackground],
                ),
              ),
              child: Builder(
                builder: (context) {
                  final incomingMessages = ref
                      .watch(messagesProvider)
                      .where((m) => m.senderId == widget.chat.id)
                      .toList();

                  final sentMessages = ref
                      .watch(sentMessagesProvider)
                      .where((m) => m.recipientId == widget.chat.id)
                      .toList();

                  final allMessages = [
                    ...widget.chat.messages
                        .map((m) => _TimedMessage(m, DateTime(2000))),
                    ...incomingMessages.map((m) => _TimedMessage(
                          Message(
                            id: m.messageId,
                            text: m.plaintext,
                            time:
                                '${m.receivedAt.hour}:${m.receivedAt.minute.toString().padLeft(2, '0')}',
                            isSentByMe: false,
                          ),
                          m.receivedAt,
                        )),
                    ...sentMessages.map((m) => _TimedMessage(
                          Message(
                            id: m.messageId,
                            text: m.ciphertext,
                            time: m.time,
                            isSentByMe: true,
                          ),
                          m.sentAt,
                        )),
                  ];

                  allMessages
                      .sort((a, b) => a.timestamp.compareTo(b.timestamp));

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: allMessages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: inputColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }

                      final item = allMessages[index - 1];
                      return ChatBubble(
                        message: item.message,
                        isSentByMe: item.message.isSentByMe,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: secondaryBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.camera_alt, color: textSecondary),
                const SizedBox(width: 8),
                const Icon(Icons.photo_library, color: textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: inputColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(color: textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final text = _messageController.text.trim();
                      if (text.isEmpty) return;
                      _messageController.clear();
                      await _sendMessage(text);
                    },
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagesProvider.notifier).markAsRead(widget.chat.id);
    });
  }
}

class _TimedMessage {
  final Message message;
  final DateTime timestamp;
  _TimedMessage(this.message, this.timestamp);
}