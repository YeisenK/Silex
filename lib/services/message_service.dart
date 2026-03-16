import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';

class MessageService {
  static final _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  static Future<Options> _authOptions() async {
    final token = await StorageService.getJwt();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String recipientId,
    required String ratchetKey,
    required int prevCounter,
    required int msgCounter,
    required String ciphertext,
    required String iv,
    required String senderIdentityKey,
    int? usedOtpkId,
    String messageType = 'text',
  }) async {
    final response = await _dio.post(
      '/messages',
      data: {
        'recipientId': recipientId,
        'ratchetKey': ratchetKey,
        'prevCounter': prevCounter,
        'msgCounter': msgCounter,
        'ciphertext': ciphertext,
        'iv': iv,
        'messageType': messageType,
        'senderIdentityKey': senderIdentityKey,
        if (usedOtpkId != null) 'usedOtpkId': usedOtpkId,
      },
      options: await _authOptions(),
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getPendingMessages() async {
    final response = await _dio.get(
      '/messages/pending',
      options: await _authOptions(),
    );
    return response.data as List<dynamic>;
  }
  
}

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