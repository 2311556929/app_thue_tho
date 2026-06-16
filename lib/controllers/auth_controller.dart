// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart'; // ← THÊM

class AuthController with ChangeNotifier {
  AppUser? currentUser;
  bool isLoading = false;

  void setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  // ── Đăng nhập ─────────────────────────────────────────────
  Future<void> loginWithEmail(
      String email, String password, BuildContext context) async {
    setLoading(true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (userDoc.exists) {
        currentUser =
            AppUser.fromJson(userDoc.data() as Map<String, dynamic>);

        // ✅ LƯU FCM TOKEN NGAY SAU ĐĂNG NHẬP
        await NotificationService.onUserLoggedIn();

        final role = currentUser!.role;
        if (!context.mounted) return;

        if (role == 'customer' || role == 'khach_hang') {
          Navigator.pushReplacementNamed(context, '/customer-home');
        } else if (role == 'provider' || role == 'tho') {
          Navigator.pushReplacementNamed(context, '/provider-home');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy thông tin người dùng.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi đăng nhập';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Email hoặc mật khẩu không đúng';
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      setLoading(false);
    }
  }

  // ── Đăng ký ───────────────────────────────────────────────
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
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'avatar': '',
        'completedOrders': 0,
        'usedTechnicians': 0,
        'points': 0,
        'fcmToken': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ LƯU FCM TOKEN NGAY SAU ĐĂNG KÝ
      await NotificationService.onUserLoggedIn();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi đăng ký';
      if (e.code == 'email-already-in-use') message = 'Email này đã được sử dụng';
      if (e.code == 'weak-password') message = 'Mật khẩu quá yếu (ít nhất 6 ký tự)';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      setLoading(false);
    }
  }

  // ── Quên mật khẩu ─────────────────────────────────────────
  Future<bool> forgotPassword(String email, BuildContext context) async {
    setLoading(true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Đã gửi link đặt lại mật khẩu đến email của bạn!'),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Không thể gửi email';
      if (e.code == 'invalid-email') message = 'Email không hợp lệ';
      if (e.code == 'user-not-found') message = 'Email này chưa được đăng ký';
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return false;
    } finally {
      setLoading(false);
    }
  }

  // ── Đăng xuất ─────────────────────────────────────────────
  Future<void> logout(BuildContext context) async {
    // Xóa FCM token khỏi Firestore trước khi logout
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': '',
        });
      }
    } catch (_) {}

    await FirebaseAuth.instance.signOut();
    currentUser = null;
    notifyListeners();

    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
}
