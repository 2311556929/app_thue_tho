// ============================================================
// lib/services/job_service.dart
// ============================================================
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:appthuetho/models/job_model.dart';
import 'package:appthuetho/services/fcm_sender.dart'; // Import đúng 1 lần duy nhất

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tạo job mới và tìm thợ gợi ý
  Future<Map<String, dynamic>> createJobAndGetSuggestions(Job job) async {
    try {
      // 1. Tạo job trên Firestore
      DocumentReference jobRef = await _firestore.collection('jobs').add({
        'customerId': job.customerId,
        'customerName': job.customerName,
        'customerPhone': job.customerPhone,
        'customerAddress': job.customerAddress,
        'serviceType': job.serviceType,
        'description': job.description,
        'imagePath': job.imagePath,
        'latitude': job.latitude,
        'longitude': job.longitude,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'estimatedPrice': _estimatePrice(job.serviceType),
      });

      // 2. Tìm thợ phù hợp gần nhất
      List<Map<String, dynamic>> suggestedTechnicians = await _findNearbyTechnicians(
        serviceType: job.serviceType,
        latitude: job.latitude,
        longitude: job.longitude,
      );

      // 3. ✅ Thông báo cho từng thợ gợi ý (ĐÃ THÊM AWAIT)
      for (final tech in suggestedTechnicians) {
        final techId = tech['id']?.toString() ?? '';
        if (techId.isNotEmpty) {
          await FcmSender.notifyNewJobToTechnician(
            technicianId: techId,
            jobId: jobRef.id,
            serviceType: job.serviceType,
            customerAddress: job.customerAddress,
            estimatedPrice: (tech['estimatedPrice'] ?? 0).toDouble(),
          );
        }
      }

      return {
        'success': true,
        'jobId': jobRef.id,
        'suggestedTechnicians': suggestedTechnicians,
      };
    } catch (e) {
      print('Lỗi tạo job: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Thợ nhận đơn
  Future<bool> acceptJob(String jobId, String technicianId) async {
    try {
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final techDoc = await _firestore.collection('users').doc(technicianId).get();

      if (!jobDoc.exists) return false;

      final jobData = jobDoc.data()!;
      final customerId = jobData['customerId'] as String? ?? '';
      final serviceType = jobData['serviceType'] as String? ?? 'dịch vụ';
      final techName = techDoc.data()?['name'] as String? ?? 'Thợ';

      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'accepted',
        'technicianId': technicianId,
        'technicianName': techName,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Gửi thông báo cho khách hàng (ĐÃ THÊM AWAIT)
      if (customerId.isNotEmpty) {
        await FcmSender.notifyJobAccepted(
          customerId: customerId,
          jobId: jobId,
          technicianName: techName,
          serviceType: serviceType,
        );
      }

      return true;
    } catch (e) {
      print('Lỗi nhận đơn: $e');
      return false;
    }
  }

  // Thợ đang trên đường tới
  Future<bool> markOnTheWay(String jobId) async {
    try {
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (!jobDoc.exists) return false;

      final jobData = jobDoc.data()!;
      final customerId = jobData['customerId'] as String? ?? '';
      final techName = jobData['technicianName'] as String? ?? 'Thợ';

      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'on_the_way',
        'onTheWayAt': FieldValue.serverTimestamp(),
      });

      // ✅ Thông báo cho khách (ĐÃ THÊM AWAIT)
      if (customerId.isNotEmpty) {
        await FcmSender.notifyTechnicianOnTheWay(
          customerId: customerId,
          jobId: jobId,
          technicianName: techName,
        );
      }

      return true;
    } catch (e) {
      print('Lỗi on_the_way: $e');
      return false;
    }
  }

  // Bắt đầu làm việc
  Future<bool> startJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Lỗi start job: $e');
      return false;
    }
  }

  // Hoàn thành công việc
  Future<bool> completeJob(String jobId) async {
    try {
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (!jobDoc.exists) return false;

      final jobData = jobDoc.data()!;
      final customerId = jobData['customerId'] as String? ?? '';
      final serviceType = jobData['serviceType'] as String? ?? 'dịch vụ';

      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Thông báo hoàn thành cho khách (ĐÃ THÊM AWAIT)
      if (customerId.isNotEmpty) {
        await FcmSender.notifyJobCompleted(
          customerId: customerId,
          jobId: jobId,
          serviceType: serviceType,
        );
      }

      return true;
    } catch (e) {
      print('Lỗi complete job: $e');
      return false;
    }
  }

  // Hủy đơn
  Future<bool> cancelJob(String jobId, String reason) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'cancelled',
        'cancelReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Lỗi cancel job: $e');
      return false;
    }
  }

  // ─── PRIVATE HELPERS ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> _findNearbyTechnicians({
    required String serviceType,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .get();

      List<Map<String, dynamic>> result = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final services =
        List<String>.from(data['serviceTypes'] ?? data['services'] ?? []);
        if (!services.contains(serviceType)) continue;

        final techLat = (data['latitude'] ?? 0.0).toDouble();
        final techLng = (data['longitude'] ?? 0.0).toDouble();
        final distance = _calcDistance(latitude, longitude, techLat, techLng);

        if (distance <= 10.0) {
          result.add({
            'id': doc.id,
            'name': data['name'] ?? '',
            'phone': data['phone'] ?? '',
            'rating': (data['rating'] ?? 4.5).toDouble(),
            'avatar': data['avatar'] ?? 'https://i.pravatar.cc/150',
            'serviceTypes': services,
            'distance': distance,
            'completedJobs': data['completedJobs'] ?? 0,
            'latitude': techLat,
            'longitude': techLng,
          });
        }
      }

      result.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));
      return result.take(10).toList();
    } catch (e) {
      print('Lỗi tìm thợ: $e');
      return [];
    }
  }

  double _calcDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  double _estimatePrice(String serviceType) {
    const prices = {
      'Sửa điện': 200000,
      'Sửa nước': 150000,
      'Sửa điều hòa': 300000,
      'Vệ sinh máy lạnh': 200000,
      'Sửa tủ lạnh': 250000,
      'Sửa máy giặt': 200000,
      'Sửa TV': 300000,
    };
    return (prices[serviceType] ?? 150000).toDouble();
  }

  // Lấy danh sách đơn pending
  Future<List<Job>> getPendingJobs() async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['createdAt'] =
            (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
                DateTime.now().toIso8601String();
        return Job.fromJson(data, doc.id);
      }).toList();
    } catch (e) {
      print('Lỗi getPendingJobs: $e');
      return [];
    }
  }

  Future<List<Job>> getCustomerJobs(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['createdAt'] =
            (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
                DateTime.now().toIso8601String();
        return Job.fromJson(data, doc.id);
      }).toList();
    } catch (e) {
      print('Lỗi getCustomerJobs: $e');
      return [];
    }
  }

  Future<List<Job>> getTechnicianJobs(String technicianId) async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('technicianId', isEqualTo: technicianId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['createdAt'] =
            (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
                DateTime.now().toIso8601String();
        return Job.fromJson(data, doc.id);
      }).toList();
    } catch (e) {
      print('Lỗi getTechnicianJobs: $e');
      return [];
    }
  }
}