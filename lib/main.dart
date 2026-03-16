import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silex/core/pin_service.dart';
import 'package:silex/core/storage_service.dart';
import 'package:silex/providers/message_provider.dart';
import 'package:silex/screens/chat_list_screen.dart';
import 'package:silex/screens/login_screen.dart';
import 'package:silex/screens/unlock_screen.dart';
import 'package:silex/services/socket_service.dart';
import 'package:silex/core/crypto_service.dart';
import 'package:silex/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isLoggedIn = await StorageService.getJwt() != null;
  final hasPinConfigured = isLoggedIn && await PinService.isPinConfigured();

  // only auto-connect if logged in WITHOUT pin (pin unlock will connect later)
  if (isLoggedIn && !hasPinConfigured) {
    await SocketService.connect();
    await CryptoService.ensureIdentityPublic();
  }

  runApp(
    ProviderScope(
      child: MyApp(
        isLoggedIn: isLoggedIn,
        hasPinConfigured: hasPinConfigured,
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool isLoggedIn;
  final bool hasPinConfigured;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.hasPinConfigured,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SocketService.onMessageReceived = (data) {
      ref.read(messagesProvider.notifier).addMessage(data);
    };

    final Widget home;
    if (!isLoggedIn) {
      home = const LoginScreen();
    } else if (hasPinConfigured) {
      home = const UnlockScreen();
    } else {
      home = const ChatListScreen();
    }

    return MaterialApp(
      title: 'Silex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: home,
      routes: {
        '/home': (_) => const ChatListScreen(),
        '/login': (_) => const LoginScreen(),
        '/unlock': (_) => const UnlockScreen(),
      },
    );
  }
}
