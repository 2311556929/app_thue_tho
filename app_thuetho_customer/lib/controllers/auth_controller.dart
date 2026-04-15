import '../models/user_model.dart';
import 'package:flutter/material.dart';

// Import thư viện Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController with ChangeNotifier {
  AppUser? currentUser;
  bool isLoading = false;

  // Hàm cập nhật trạng thái loading
  void setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  // ==========================================
  // 1. ĐĂNG NHẬP BẰNG EMAIL & MẬT KHẨU
  // ==========================================
  Future<void> loginWithEmail(String email, String password, BuildContext context) async {
    setLoading(true);
    try {
      // Xác thực với Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lấy thông tin chi tiết của User từ Firestore (để biết là Khách hay Thợ)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        // Gán toàn bộ dữ liệu thật vào currentUser thông qua fromJson
        currentUser = AppUser.fromJson(userDoc.data() as Map<String, dynamic>);

        // Lấy role từ currentUser để kiểm tra chuyển trang
        String role = currentUser!.role;

        // Chuyển hướng màn hình tùy theo vai trò
        if (role == 'khach_hang' || role == 'customer') {
          Navigator.pushReplacementNamed(context, '/customer-home');
        } else {
          Navigator.pushReplacementNamed(context, '/provider-home');
        }

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thành công!'), backgroundColor: Colors.green)
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: Không tìm thấy dữ liệu người dùng.'), backgroundColor: Colors.red)
        );
      }

    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi đăng nhập';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'Sai email hoặc mật khẩu';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } finally {
      setLoading(false);
    }
  }

  // ==========================================
  // 2. ĐĂNG KÝ BẰNG EMAIL & LƯU INFO VÀO FIRESTORE
  // ==========================================
  Future<void> registerWithEmail(String email, String password, String name,String phone, String role, BuildContext context) async {
    setLoading(true);
    try {
      // 1. Tạo tài khoản đăng nhập trên Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Lưu thông tin hồ sơ + Các chỉ số mặc định vào database Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'completedOrders': 0,    // Đơn mặc định 0
        'usedTechnicians': 0,    // Thợ dùng mặc định 0
        'points': 0,             // Điểm mặc định 0
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.'), backgroundColor: Colors.green),
      );

      // Đăng ký xong tự động quay về trang Đăng nhập
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi đăng ký';
      if (e.code == 'email-already-in-use') {
        message = 'Email này đã được đăng ký!';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu!';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } finally {
      setLoading(false);
    }
  }

  // ==========================================
  // 3. ĐĂNG XUẤT
  // ==========================================
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    currentUser = null; // Xóa dữ liệu user khi đăng xuất
    notifyListeners();
    // Bỏ comment dòng này để app tự văng ra màn login khi nhấn Đăng xuất
    Navigator.pushReplacementNamed(context, '/login');
  }
}