import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants.dart';
import '../core/storage_service.dart';
import 'message_service.dart';

class SocketService {
  static IO.Socket? _socket;

  // Callback that is called when a message arrives
  static Function(Map<String, dynamic>)? onMessageReceived;

  static bool get isConnected => _socket?.connected ?? false;


  static Future<void> connect() async {
  if (isConnected) return;

  final token = await StorageService.getJwt();
    if (token == null) return;

    _socket = IO.io(
      AppConstants.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) async {
      print('[Socket] Connected');
      
      // download messages that arrived while it was offline
      try {
        final pending = await MessageService.getPendingMessages();
        if (pending.isNotEmpty) {
          for (final message in pending) {
            if (onMessageReceived != null) {
              onMessageReceived!(Map<String, dynamic>.from(message));
            }
          }
          print('[Socket] Delivered ${pending.length} pending messages');
        }
      } catch (e) {
        print('[Socket] Error fetching pending messages: $e');
      }
    });

    _socket!.onDisconnect((_) {
      print('[Socket] Disconnected');
    });

    _socket!.onConnectError((error) {
      print('[Socket] Connection error: $error');
    });

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