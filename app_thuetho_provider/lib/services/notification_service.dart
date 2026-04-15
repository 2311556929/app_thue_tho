import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. Xin quyền thông báo
    await _messaging.requestPermission();

    // 2. Lấy FCM Token
    String? token = await _messaging.getToken();
    print('🔑 FCM Token: $token');

    // 3. Gửi Token lên Server (Có Try-Catch để chống crash app)
    if (token != null) {
      try {
        print('⏳ Đang gửi token lên server...');
        final response = await http.post(
          Uri.parse('http://192.168.57.10:3000/api/register-token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': 'customer_001', 'fcmToken': token}),
        ).timeout(const Duration(seconds: 5)); // Nếu 5 giây server không phản hồi thì tự huỷ lệnh để app chạy tiếp

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Đăng ký FCM Token lên server thành công!');
        } else {
          print('⚠️ Server trả về mã lỗi: ${response.statusCode}');
        }
      } catch (e) {
        // App sẽ nhảy vào đây nếu không có mạng, sai IP, hoặc server chưa bật
        // Nhờ có khối catch này, app KHÔNG bị crash màn hình trắng nữa!
        print('❌ Không thể kết nối tới server (Bỏ qua để app tiếp tục chạy). Chi tiết: $e');
      }
    }

    // 4. Lắng nghe thông báo khi app đang mở
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Nhận thông báo: ${message.notification?.title}');
      // SnackBar sẽ hiển thị ở mọi màn hình
    });
  }
}