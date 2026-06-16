import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:appthuetho/controllers/auth_controller.dart';
import 'package:appthuetho/models/user_model.dart';
import 'package:appthuetho/views/customer/post_job_screen.dart';

void main() {
  group('PostJobScreen Tests', () {
    late AuthController authController;

    setUpAll(() async {
      await Firebase.initializeApp();
      authController = AuthController();
      authController.currentUser = AppUser(
        id: 'test123',
        name: 'Test User',
        phone: '0123456789',
        role: 'customer',
        email: 'test@example.com',
      );
    });

    testWidgets('PostJobScreen build thành công và hiển thị form', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [ChangeNotifierProvider(create: (_) => authController)],
            child: const PostJobScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 3)); // Tăng thời gian để initState chạy xong

      expect(find.textContaining('Đặt dịch vụ'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Tìm thợ ngay'), findsOneWidget);
    });

    testWidgets('Chọn dịch vụ và nhập mô tả', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [ChangeNotifierProvider(create: (_) => authController)],
            child: const PostJobScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      // Mở dropdown
      await tester.tap(find.byType(DropdownButtonFormField));
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      await tester.tap(find.text('Sửa điện').last);
      await tester.pump(const Duration(milliseconds: 500));

      // Nhập mô tả
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mô tả tình trạng...'),
        'Tủ lạnh không lạnh, kêu to',
      );

      expect(find.text('Tủ lạnh không lạnh, kêu to'), findsOneWidget);
    });
  });
}