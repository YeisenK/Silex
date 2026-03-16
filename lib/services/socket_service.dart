import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants.dart';
import '../core/storage_service.dart';
import 'message_service.dart';

class SocketService {
  static io.Socket? _socket;

  static Function(Map<String, dynamic>)? onMessageReceived;

  static bool get isConnected => _socket?.connected ?? false;

  static Future<void> connect() async {
    if (isConnected) return;

    final token = await StorageService.getJwt();
    if (token == null) return;

    _socket = io.io(
      AppConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) async {
      try {
        final pending = await MessageService.getPendingMessages();
        if (pending.isNotEmpty) {
          for (final message in pending) {
            if (onMessageReceived != null) {
              onMessageReceived!(Map<String, dynamic>.from(message));
            }
          }
        }
      } catch (_) {}
    });

    _socket!.onDisconnect((_) {});

    _socket!.onConnectError((_) {});

    _socket!.on('message', (data) {
      if (onMessageReceived != null && data is Map<String, dynamic>) {
        onMessageReceived!(data);
      }
    });

    _socket!.connect();
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  static Future<void> reconnect() async {
    disconnect();
    await connect();
  }
}