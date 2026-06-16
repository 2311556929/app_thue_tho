import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:appthuetho/controllers/auth_controller.dart';
import 'package:appthuetho/views/auth/login_screen.dart';

void main() {
  group('LoginScreen Tests', () {
    late AuthController authController;

    setUpAll(() async {
      await Firebase.initializeApp(); // ← Khởi tạo Firebase cho test
      authController = AuthController();
    });

    testWidgets('LoginScreen hiển thị đầy đủ và không crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [ChangeNotifierProvider(create: (_) => authController)],
            child: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('Đăng nhập'), findsOneWidget);
      expect(find.byType(TextField), findsAtLeast(1));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Nhập email + password và bấm Đăng nhập', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [ChangeNotifierProvider(create: (_) => authController)],
            child: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, '123456');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(authController.isLoading, isFalse);
    });
  });
}