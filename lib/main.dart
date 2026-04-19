import 'package:appthuetho/controllers/auth_controller.dart';
import 'package:appthuetho/data/csv_knowledge_base.dart';
import 'package:appthuetho/services/rag_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'controllers/customer_controller.dart';
import 'controllers/provider_controller.dart';
import 'package:firebase_core/firebase_core.dart';
// Đảm bảo bạn import đúng các đường dẫn này theo project của bạn nhé
import 'views/auth/login_screen.dart';
import 'views/customer/customer_main_screen.dart';
import 'views/provider/provider_main_screen.dart'; // Import màn hình của provider

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📢 Nhận thông báo nền: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  CsvKnowledgeBase.loadData(); // không await - chạy nền

  // ✅ THÊM: Seed CSV lên Firestore để backup (1 lần)
  RagService.seedCsvToFirestore(); // không await - chạy nền

  // await NotificationService.init();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        fontFamily: 'Roboto',
      ),
      // --- PHẦN THAY ĐỔI Ở ĐÂY ---
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/customer-home': (context) => const CustomerMainScreen(),
        '/provider-home': (context) => const ProviderMainScreen(),
      },
      // Xoá bỏ dòng: home: const CustomerMainScreen(),
    );
  }
}