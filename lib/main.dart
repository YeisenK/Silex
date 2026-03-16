import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silex/core/storage_service.dart';
import 'package:silex/providers/message_provider.dart';
import 'package:silex/screens/chat_list_screen.dart';
import 'package:silex/screens/login_screen.dart';
import 'package:silex/services/socket_service.dart';
import 'package:silex/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await StorageService.getJwt() != null;

  if (isLoggedIn) {
    await SocketService.connect();
  }

  runApp(
    ProviderScope(
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SocketService.onMessageReceived = (data) {
      ref.read(messagesProvider.notifier).addMessage(data);
    };

    return MaterialApp(
      title: 'Silex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isLoggedIn ? const ChatListScreen() : const LoginScreen(),
      routes: {
        '/home': (_) => const ChatListScreen(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}