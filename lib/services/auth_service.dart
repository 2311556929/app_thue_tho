import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Emulator

  // Đăng ký
  Future<bool> register({
    required String phone,
    required String name,
    required String role, // 'customer' or 'provider'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'name': name, 'role': role}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      return false;
    }
  }

  // Đăng nhập (OTP giả lập)
  Future<AppUser?> login(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppUser.fromJson(data['user']);
      }
    } catch (e) {
      print('Lỗi đăng nhập: $e');
    }
    return null;
  }
  // ==================== QUÊN MẬT KHẨU ====================
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        print('✅ Đã gửi link reset mật khẩu đến $email');
        return true;
      } else {
        print('❌ Lỗi gửi reset password: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Lỗi kết nối khi gửi reset password: $e');
      return false;
    }
  }
  // Đăng xuất
  Future<void> logout() async {
    // Sau này có thể xóa token Firebase nếu cần
    print('Đã đăng xuất');
  }
}