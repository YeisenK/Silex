import 'package:flutter/material.dart';
import 'screens/chat_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B24),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00A884),
          secondary: Color(0xFF00A884),
          surface: Color(0xFF1E2A32),
          background: Color(0xFF0D1B24),
          error: Color(0xFFF15E6C),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1B24),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E2A32),
          selectedItemColor: Color(0xFF00A884),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00A884),
          foregroundColor: Colors.white,
        ),
        // Use textTheme to define font families
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'GoogleSans'),
          bodyMedium: TextStyle(fontFamily: 'GoogleSans'),
          titleLarge: TextStyle(fontFamily: 'GoogleSans'),
          titleMedium: TextStyle(fontFamily: 'GoogleSans'),
          labelLarge: TextStyle(fontFamily: 'GoogleSans'),
        ),
        primaryTextTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'GoogleSans'),
          bodyMedium: TextStyle(fontFamily: 'GoogleSans'),
          titleLarge: TextStyle(fontFamily: 'GoogleSans'),
          titleMedium: TextStyle(fontFamily: 'GoogleSans'),
        ),
      ),
      home: const ChatListScreen(),
    );
  }
}