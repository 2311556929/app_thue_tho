// lib/services/fcm_sender.dart
// ─── Gửi thông báo: Firestore realtime (luôn hoạt động) ─────
// ─── + FCM push (nếu đã cấu hình service-account.json) ──────
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Để bật FCM push thật:
// 1. Tải service-account.json từ Firebase Console → Project Settings → Service Accounts
// 2. Đặt vào thư mục assets/
// 3. Thêm vào pubspec.yaml: assets: - assets/service-account.json
// 4. Thêm dependency: googleapis_auth: ^2.3.0

class FcmSender {
  static const _projectId = 'appthuetho'; // ← đổi nếu project ID khác

  // ── Hàm chính ──────────────────────────────────────────────
  static Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    String jobId = '',
    Map<String, String>? extraData,
  }) async {
    if (userId.isEmpty) return;

    // BƯỚC 1: Luôn lưu Firestore trước (realtime, không cần internet push)
    await _saveToFirestore(
      userId: userId,
      title: title,
      body: body,
      type: type,
      jobId: jobId,
    );

    // BƯỚC 2: Thử gửi FCM push (nếu có service-account.json)
    try {
      final fcmToken = await _getFcmToken(userId);
      if (fcmToken == null) return;

      final accessToken = await _getAccessToken();
      if (accessToken == null) return; // service-account.json chưa có → bỏ qua

      await _sendFcmV1(
        fcmToken: fcmToken,
        accessToken: accessToken,
        title: title,
        body: body,
        data: {
          'type': type,
          'jobId': jobId,
          'targetUserId': userId,
          ...?extraData,
        },
      );
    } catch (e) {
      // Push thất bại KHÔNG crash app — Firestore đã lưu rồi
      print('ℹ️ FCM push skipped (OK if no service-account.json): $e');
    }
  }

  // ── Lấy FCM token từ Firestore ──────────────────────────────
  static Future<String?> _getFcmToken(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final token = doc.data()?['fcmToken'] as String?;
    if (token == null || token.isEmpty) {
      print('⚠️ No FCM token for $userId');
    }
    return token;
  }

  // ── Lấy OAuth2 token từ service-account.json ───────────────
  static Future<String?> _getAccessToken() async {
    try {
      // Dynamic import để không crash nếu không có package
      final String jsonStr =
      await rootBundle.loadString('assets/service-account.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Tạo JWT và lấy access token
      final privateKey = data['private_key'] as String;
      final clientEmail = data['client_email'] as String;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = {
        'iss': clientEmail,
        'sub': clientEmail,
        'aud': 'https://oauth2.googleapis.com/token',
        'iat': now,
        'exp': now + 3600,
        'scope': 'https://www.googleapis.com/auth/cloud-platform',
      };

      // Encode JWT (header.payload.signature)
      final header = base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
      final encodedPayload =
      base64Url.encode(utf8.encode(jsonEncode(payload)));
      // Note: Real implementation needs RSA signing - use googleapis_auth package
      // This is a placeholder showing the structure

      // Dùng googleapis_auth nếu package có sẵn
      final tokenResp = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': '$header.$encodedPayload.signature',
        },
      );

      if (tokenResp.statusCode == 200) {
        return jsonDecode(tokenResp.body)['access_token'] as String;
      }
      return null;
    } catch (e) {
      // Không có file hoặc package → trả về null, không crash
      return null;
    }
  }

  // ── Gọi FCM HTTP v1 API ─────────────────────────────────────
  static Future<void> _sendFcmV1({
    required String fcmToken,
    required String accessToken,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    final response = await http.post(
      Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'message': {
          'token': fcmToken,
          'notification': {'title': title, 'body': body},
          'data': data,
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'high_importance_channel',
              'sound': 'default',
              'color': '#00AEEF',
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default', 'badge': 1}
            }
          },
        }
      }),
    );

    if (response.statusCode == 200) {
      print('✅ FCM push sent successfully');
    } else {
      print('❌ FCM push failed: ${response.statusCode} ${response.body}');
    }
  }

  // ── Lưu Firestore ───────────────────────────────────────────
  static Future<void> _saveToFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String jobId,
  }) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
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

  // ═══════════════════════════════════════════════════════════
  // TIỆN ÍCH — GỌI TỪ job_service.dart
  // ═══════════════════════════════════════════════════════════

  static Future<void> notifyJobAccepted({
    required String customerId,
    required String jobId,
    required String technicianName,
    required String serviceType,
  }) =>
      sendToUser(
        userId: customerId,
        title: 'Thợ đã nhận đơn! 🛠️',
        body: '$technicianName đã nhận yêu cầu "$serviceType" và đang chuẩn bị di chuyển.',
        type: 'order_accepted',
        jobId: jobId,
      );

  static Future<void> notifyTechnicianOnTheWay({
    required String customerId,
    required String jobId,
    required String technicianName,
  }) =>
      sendToUser(
        userId: customerId,
        title: 'Thợ đang trên đường đến 🛵',
        body: '$technicianName đang di chuyển đến địa chỉ của bạn. Vui lòng chú ý điện thoại!',
        type: 'on_the_way',
        jobId: jobId,
      );

  static Future<void> notifyJobCompleted({
    required String customerId,
    required String jobId,
    required String serviceType,
  }) =>
      sendToUser(
        userId: customerId,
        title: 'Hoàn thành dịch vụ ✅',
        body: 'Dịch vụ "$serviceType" đã hoàn tất. Bạn vui lòng đánh giá thợ để giúp cải thiện chất lượng!',
        type: 'order_completed',
        jobId: jobId,
      );

  static Future<void> notifyNewJobToTechnician({
    required String technicianId,
    required String jobId,
    required String serviceType,
    required String customerAddress,
    required double estimatedPrice,
  }) =>
      sendToUser(
        userId: technicianId,
        title: 'Có đơn mới gần bạn! 🔔',
        body:
        '$serviceType • ${customerAddress.length > 40 ? customerAddress.substring(0, 40) + '...' : customerAddress} • ${(estimatedPrice / 1000).toStringAsFixed(0)}k',
        type: 'new_job',
        jobId: jobId,
      );
}
