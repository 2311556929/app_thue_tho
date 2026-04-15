import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthController with ChangeNotifier {
  AppUser? currentUser;
  bool isLoading = false;

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
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        currentUser = AppUser.fromJson(userDoc.data() as Map<String, dynamic>);

        String role = currentUser!.role;

        if (role == 'customer' || role == 'khach_hang') {
          Navigator.pushReplacementNamed(context, '/customer-home');
        } else if (role == 'provider' || role == 'tho') {
          Navigator.pushReplacementNamed(context, '/provider-home');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin người dùng.'), backgroundColor: Colors.red),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi đăng nhập';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Email hoặc mật khẩu không đúng';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      setLoading(false);
    }
  }

  // ==========================================
  // 2. ĐĂNG KÝ BẰNG EMAIL
  // ==========================================
  Future<void> registerWithEmail(
      String email,
      String password,
      String name,
      String phone,
      String role,
      BuildContext context,
      ) async {
    setLoading(true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'completedOrders': 0,
        'usedTechnicians': 0,
        'points': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.'), backgroundColor: Colors.green),
      );

      Navigator.pop(context); // Quay về Login
    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi đăng ký';
      if (e.code == 'email-already-in-use') message = 'Email này đã được sử dụng';
      if (e.code == 'weak-password') message = 'Mật khẩu quá yếu (ít nhất 6 ký tự)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      setLoading(false);
    }
  }

  // ==========================================
  // 3. QUÊN MẬT KHẨU (ĐÃ HOÀN THIỆN)
  // ==========================================
  Future<bool> forgotPassword(String email, BuildContext context) async {
    setLoading(true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi link đặt lại mật khẩu đến email của bạn!'),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Không thể gửi email';
      if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ';
      } else if (e.code == 'user-not-found') {
        message = 'Email này chưa được đăng ký';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return false;
    } finally {
      setLoading(false);
    }
  }

  // ==========================================
  // 4. ĐĂNG XUẤT
  // ==========================================
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    currentUser = null;
    notifyListeners();

    Navigator.pushReplacementNamed(context, '/login');
  }
}