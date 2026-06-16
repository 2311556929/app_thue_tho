// lib/services/notification_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Background handler (top-level, không được đặt trong class) ──
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    final uid = message.data['targetUserId'] as String?;
    if (uid == null || uid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .add({
      'title': message.notification?.title ?? '',
      'message': message.notification?.body ?? '',
      'type': message.data['type'] ?? 'system',
      'jobId': message.data['jobId'] ?? '',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────
class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // 1. Xin quyền thông báo
    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2. Cấu hình local notification (popup khi app mở)
    await _setupLocalNotifications();

    // 3. Nhận message khi app đang FOREGROUND
    FirebaseMessaging.onMessage.listen((msg) async {
      // Hiện popup hệ thống
      await _showLocal(
        title: msg.notification?.title ?? 'Thông báo mới',
        body: msg.notification?.body ?? '',
        payload: jsonEncode(msg.data),
      );
      // Lưu vào Firestore để hiện trong tab Thông báo
      await _saveToFirestore(msg);
    });

    // 4. Tap vào notification khi app BACKGROUND → foreground
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // 5. Tap khi app bị TẮT hoàn toàn
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleTap(initial);

    // 6. Đăng ký FCM token ngay nếu đã login
    await _refreshToken();

    // Auto-refresh token sau khi login/logout
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _refreshToken();
    });

    _fcm.onTokenRefresh.listen((token) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _saveToken(uid, token);
    });

    _initialized = true;
    print('✅ NotificationService ready');
  }

  /// Gọi ngay sau khi đăng nhập thành công
  static Future<void> onUserLoggedIn() => _refreshToken();

  // ── Private helpers ──────────────────────────────────────
  static Future<void> _refreshToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await _fcm.getToken();
      if (token != null) await _saveToken(user.uid, token);
    } catch (e) {
      print('⚠️ FCM token: $e');
    }
  }

  static Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  static Future<void> _saveToFirestore(RemoteMessage msg) async {
    try {
      final uid = msg.data['targetUserId'] as String? ??
          FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;
      await _writeNotif(
        uid: uid,
        title: msg.notification?.title ?? '',
        body: msg.notification?.body ?? '',
        type: msg.data['type'] ?? 'system',
        jobId: msg.data['jobId'] ?? '',
      );
    } catch (e) {
      print('⚠️ saveToFirestore: $e');
    }
  }

  static void _handleTap(RemoteMessage msg) {
    final type = msg.data['type'];
    final jobId = msg.data['jobId'];
    print('📬 Notification tapped type=$type jobId=$jobId');
    // Điều hướng xử lý ở navigatorKey nếu cần
  }

  static Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(const InitializationSettings(
      android: android,
      iOS: ios,
    ));

    // Android 8+ cần channel
    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      'high_importance_channel',
      'Thông báo App Thuê Thợ',
      description: 'Đơn hàng và cập nhật trạng thái',
      importance: Importance.high,
      playSound: true,
    ));
  }

  static Future<void> _showLocal({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Thông báo App Thuê Thợ',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF00AEEF),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ── PUBLIC: Ghi thẳng vào Firestore + hiện local popup ───
  /// Dùng khi không cần FCM push (app đang chạy, hoặc không có server key)
  static Future<void> saveAndShow({
    required String userId,
    required String title,
    required String body,
    required String type,
    String jobId = '',
  }) async {
    if (userId.isEmpty) return;
    // Lưu Firestore (realtime stream sẽ hiện lên tab Thông báo ngay)
    await _writeNotif(
        uid: userId, title: title, body: body, type: type, jobId: jobId);
    // Hiện popup local nếu đây là thiết bị của user đang login
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == userId) {
      await _showLocal(title: title, body: body);
    }
  }

  static Future<void> _writeNotif({
    required String uid,
    required String title,
    required String body,
    required String type,
    required String jobId,
  }) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .add({
      'title': title,
      'message': body,
      'type': type,
      'jobId': jobId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}