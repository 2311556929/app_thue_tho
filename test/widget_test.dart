import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:appthuetho/main.dart';           // Đường dẫn đến main.dart của em
import 'package:appthuetho/controllers/auth_controller.dart';

void main() {
  testWidgets('App Thuê Thợ khởi động thành công', (WidgetTester tester) async {
    // Wrap với MultiProvider giống như trong main.dart của em
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthController()),
          // Nếu em có thêm controller khác thì thêm vào đây
        ],
        child: const MyApp(),
      ),
    );

    // Kiểm tra app có build thành công không
    expect(find.byType(MaterialApp), findsOneWidget);

    // Hoặc kiểm tra có thấy chữ "Hồ sơ", "Trang chủ"... tùy em muốn
    // expect(find.text('Hồ sơ'), findsOneWidget); // ví dụ
  });
}