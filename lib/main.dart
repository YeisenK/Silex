import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silex/core/pin_service.dart';
import 'package:silex/core/storage_service.dart';
import 'package:silex/providers/message_provider.dart';
import 'package:silex/screens/chat_list_screen.dart';
import 'package:silex/screens/login_screen.dart';
import 'package:silex/screens/unlock_screen.dart';
import 'package:silex/services/notification_service.dart';
import 'package:silex/services/socket_service.dart';
import 'package:silex/core/crypto_service.dart';
import 'package:silex/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final isLoggedIn = await StorageService.getJwt() != null;
  final hasPinConfigured = isLoggedIn && await PinService.isPinConfigured();

  if (isLoggedIn && !hasPinConfigured) {
    await SocketService.connect();
    await CryptoService.ensureIdentityPublic();
    await NotificationService.initialize();
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
