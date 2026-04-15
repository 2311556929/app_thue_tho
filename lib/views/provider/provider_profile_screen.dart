import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy thông tin profile thợ
  Future<Map<String, dynamic>?> getProviderProfile() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Lỗi lấy profile: $e');
      return null;
    }
  }

  // Stream profile thợ realtime
  Stream<DocumentSnapshot> streamProviderProfile() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots();
  }

  // Cập nhật profile thợ
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatar,
    List<String>? serviceTypes,
    String? bio,
    String? address,
    String? idCard,
    String? bankAccount,
    String? bankName,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (avatar != null) updateData['avatar'] = avatar;
      if (serviceTypes != null) updateData['serviceTypes'] = serviceTypes;
      if (bio != null) updateData['bio'] = bio;
      if (address != null) updateData['address'] = address;
      if (idCard != null) updateData['idCard'] = idCard;
      if (bankAccount != null) updateData['bankAccount'] = bankAccount;
      if (bankName != null) updateData['bankName'] = bankName;

      if (updateData.isNotEmpty) {
        updateData['updatedAt'] = FieldValue.serverTimestamp();

        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update(updateData);
      }

      return true;
    } catch (e) {
      print('Lỗi cập nhật profile: $e');
      return false;
    }
  }

  // Cập nhật trạng thái online/offline
  Future<bool> updateOnlineStatus(bool isOnline) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'isOnline': isOnline,
        'lastOnline': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Lỗi cập nhật online status: $e');
      return false;
    }
  }

  // Cập nhật vị trí
  Future<bool> updateLocation(double latitude, double longitude) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'latitude': latitude,
        'longitude': longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Lỗi cập nhật location: $e');
      return false;
    }
  }

  // Lấy thống kê thợ
  Future<Map<String, dynamic>> getProviderStats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'totalJobs': 0,
          'completedJobs': 0,
          'totalEarnings': 0.0,
          'rating': 0.0,
          'acceptanceRate': 0.0,
        };
      }

      // Đếm tổng số đơn
      QuerySnapshot totalJobsQuery = await _firestore
          .collection('jobs')
          .where('technicianId', isEqualTo: currentUser.uid)
          .get();

      // Đếm đơn hoàn thành
      QuerySnapshot completedJobsQuery = await _firestore
          .collection('jobs')
          .where('technicianId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      // Tính tổng thu nhập
      double totalEarnings = 0.0;
      for (var doc in completedJobsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalEarnings += (data['estimatedPrice'] ?? 0).toDouble();
      }

      // Lấy rating từ profile
      DocumentSnapshot profileDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final profileData = profileDoc.data() as Map<String, dynamic>;
      double rating = (profileData['rating'] ?? 0).toDouble();
      int totalOffered = (profileData['totalOffered'] ?? 0);

      double acceptanceRate = totalOffered > 0
          ? (totalJobsQuery.docs.length / totalOffered * 100)
          : 0.0;

      return {
        'totalJobs': totalJobsQuery.docs.length,
        'completedJobs': completedJobsQuery.docs.length,
        'totalEarnings': totalEarnings,
        'rating': rating,
        'acceptanceRate': acceptanceRate,
      };
    } catch (e) {
      print('Lỗi lấy stats: $e');
      return {
        'totalJobs': 0,
        'completedJobs': 0,
        'totalEarnings': 0.0,
        'rating': 0.0,
        'acceptanceRate': 0.0,
      };
    }
  }

  // Lấy lịch sử đơn hàng
  Stream<QuerySnapshot> streamJobHistory() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('jobs')
        .where('technicianId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Thêm service type
  Future<bool> addServiceType(String serviceType) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'serviceTypes': FieldValue.arrayUnion([serviceType]),
      });

      return true;
    } catch (e) {
      print('Lỗi thêm service type: $e');
      return false;
    }
  }

  // Xóa service type
  Future<bool> removeServiceType(String serviceType) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'serviceTypes': FieldValue.arrayRemove([serviceType]),
      });

      return true;
    } catch (e) {
      print('Lỗi xóa service type: $e');
      return false;
    }
  }

  // Upload avatar
  Future<String?> uploadAvatar(String localPath) async {
    // TODO: Implement Firebase Storage upload
    // For now, return placeholder
    return 'https://i.pravatar.cc/150?img=${DateTime.now().millisecondsSinceEpoch % 70}';
  }

  // Lấy reviews/ratings
  Stream<QuerySnapshot> streamReviews() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('reviews')
        .where('providerId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  // Tính toán rating mới khi có review
  Future<void> updateRatingAfterReview(double newRating) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final data = doc.data() as Map<String, dynamic>;
      double currentRating = (data['rating'] ?? 0).toDouble();
      int totalReviews = (data['totalReviews'] ?? 0);

      // Tính rating mới
      double updatedRating = ((currentRating * totalReviews) + newRating) / (totalReviews + 1);

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'rating': updatedRating,
        'totalReviews': totalReviews + 1,
      });
    } catch (e) {
      print('Lỗi update rating: $e');
    }
  }
}