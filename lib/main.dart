import 'package:flutter/material.dart';
import 'package:appthuetho/views/customer/customer_main_screen.dart'; // Sẽ tạo sau

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Thuê Thợ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,                    // Dùng Material Design mới nhất
        primaryColor: const Color(0xFF00AEEF), // Xanh dương Grab
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00AEEF),
          secondary: const Color(0xFFFF9500), // Cam accent
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00AEEF),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00AEEF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        fontFamily: 'Roboto',
      ),
      home: const CustomerMainScreen(), // Màn hình chính khách hàng
    );
  }
}