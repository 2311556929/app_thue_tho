import 'package:app_thuetho_customer/models/job_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

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
        job.latitude,
        job.longitude,
        job.serviceType,
      );

      // 3. Gửi thông báo cho các thợ (sẽ implement sau)
      for (var tech in suggestedTechnicians) {
        await _notifyTechnician(tech['id'], jobRef.id);
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

  // Tìm thợ gần nhất
  Future<List<Map<String, dynamic>>> _findNearbyTechnicians(
      double customerLat,
      double customerLng,
      String serviceType,
      ) async {
    try {
      // Lấy tất cả thợ có trạng thái online
      QuerySnapshot techSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('isOnline', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> nearbyTechs = [];

      for (var doc in techSnapshot.docs) {
        Map<String, dynamic> techData = doc.data() as Map<String, dynamic>;

        // Kiểm tra xem thợ có làm dịch vụ này không
        List<String> techServices = List<String>.from(techData['serviceTypes'] ?? []);
        if (!techServices.contains(serviceType)) continue;

        // Tính khoảng cách
        double techLat = techData['latitude'] ?? 0.0;
        double techLng = techData['longitude'] ?? 0.0;
        double distance = _calculateDistance(customerLat, customerLng, techLat, techLng);

        // Chỉ lấy thợ trong bán kính 10km
        if (distance <= 10.0) {
          nearbyTechs.add({
            'id': doc.id,
            'name': techData['name'] ?? 'Thợ',
            'phone': techData['phone'] ?? '',
            'avatar': techData['avatar'] ?? 'https://i.pravatar.cc/150',
            'rating': techData['rating'] ?? 4.5,
            'completedJobs': techData['completedJobs'] ?? 0,
            'serviceTypes': techServices,
            'distance': distance,
            'latitude': techLat,
            'longitude': techLng,
          });
        }
      }

      // Sắp xếp theo khoảng cách
      nearbyTechs.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      // Trả về tối đa 5 thợ gần nhất
      return nearbyTechs.take(5).toList();
    } catch (e) {
      print('Lỗi tìm thợ: $e');
      return [];
    }
  }

  // Tính khoảng cách giữa 2 điểm (Haversine formula)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat2 - lat1);
    double dLng = _toRadians(lng2 - lng1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  // Ước tính giá dịch vụ
  double _estimatePrice(String serviceType) {
    Map<String, double> basePrices = {
      'Sửa điện': 150000,
      'Sửa nước': 200000,
      'Sửa điều hòa': 300000,
      'Sửa tủ lạnh': 250000,
      'Sửa máy giặt': 200000,
      'Vệ sinh máy lạnh': 150000,
      'Thợ khác': 100000,
    };
    return basePrices[serviceType] ?? 150000;
  }

  // Thợ nhận đơn
  Future<bool> acceptJob(String jobId, String technicianId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'accepted',
        'technicianId': technicianId,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Gửi thông báo cho khách hàng
      return true;
    } catch (e) {
      print('Lỗi nhận đơn: $e');
      return false;
    }
  }

  // Lấy danh sách đơn pending cho thợ
  Future<List<Job>> getPendingJobs() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('jobs')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['createdAt'] = (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String();
        return Job.fromJson(data);
      }).toList();
    } catch (e) {
      print('Lỗi lấy pending jobs: $e');
      return [];
    }
  }

  // Lấy đơn của khách hàng
  Future<List<Job>> getCustomerJobs(String customerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('jobs')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['createdAt'] = (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String();
        return Job.fromJson(data);
      }).toList();
    } catch (e) {
      print('Lỗi lấy customer jobs: $e');
      return [];
    }
  }

  // Lấy đơn của thợ
  Future<List<Job>> getTechnicianJobs(String technicianId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('jobs')
          .where('technicianId', isEqualTo: technicianId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['createdAt'] = (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String();
        return Job.fromJson(data);
      }).toList();
    } catch (e) {
      print('Lỗi lấy technician jobs: $e');
      return [];
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
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
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

  // Gửi thông báo cho thợ (placeholder)
  Future<void> _notifyTechnician(String technicianId, String jobId) async {
    // Sẽ implement với FCM sau
    try {
      await _firestore.collection('notifications').add({
        'userId': technicianId,
        'type': 'new_job',
        'jobId': jobId,
        'title': 'Có đơn mới gần bạn!',
        'body': 'Có khách hàng cần dịch vụ gần vị trí của bạn',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Lỗi gửi notification: $e');
    }
  }

  // Stream để lắng nghe đơn mới realtime
  Stream<List<Job>> streamPendingJobs() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        data['createdAt'] = (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String();
        return Job.fromJson(data);
      }).toList();
    });
  }

  // Stream để tracking đơn hàng
  Stream<DocumentSnapshot> streamJobDetails(String jobId) {
    return _firestore.collection('jobs').doc(jobId).snapshots();
  }
}