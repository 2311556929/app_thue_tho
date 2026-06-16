// ============================================================
// lib/main.dart  — THAY TOÀN BỘ
// ============================================================
import 'package:appthuetho/controllers/auth_controller.dart';
import 'package:appthuetho/data/csv_knowledge_base.dart';
import 'package:appthuetho/services/notification_service.dart'; // ← dùng file mới
import 'package:appthuetho/services/rag_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/customer_controller.dart';
import 'controllers/provider_controller.dart';
import 'views/auth/login_screen.dart';
import 'views/customer/customer_main_screen.dart';
import 'views/provider/provider_main_screen.dart';

// ✅ Background handler — phải khai báo ở đây
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Lưu thông báo vào Firestore khi app đang tắt
  await firebaseMessagingBackgroundHandler(message); // từ notification_service.dart
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Đăng ký background handler TRƯỚC runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Init notification (xin quyền + setup local notification)
  await NotificationService.init();

  // Preload dữ liệu (chạy nền)
  CsvKnowledgeBase.loadData();
  RagService.seedCsvToFirestore();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CustomerController()),
        ChangeNotifierProvider(create: (_) => ProviderController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Thuê Thợ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF00AEEF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00AEEF),
          secondary: const Color(0xFFFF9500),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/customer-home': (context) => const CustomerMainScreen(),
        '/provider-home': (context) => const ProviderMainScreen(),
      },
    );
  }
}
