import 'package:appthuetho/models/job_model.dart';
import 'package:appthuetho/services/job_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomerController with ChangeNotifier {
  final JobService _jobService = JobService();
  List<Job> myJobs = [];
  bool isLoading = false;

  Future<void> fetchMyJobs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      myJobs = [];
      notifyListeners();
      debugPrint('❌ fetchMyJobs: Chưa đăng nhập');
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('customerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      myJobs = snapshot.docs.map((doc) {
        return Job.fromJson(doc.data(), doc.id);
      }).toList();

      debugPrint('✅ Loaded ${myJobs.length} jobs for ${user.uid}');
    } catch (e) {
      debugPrint('❌ Lỗi fetchMyJobs: $e');
      if (e.toString().contains('FAILED_PRECONDITION')) {
        debugPrint('👉 Cần tạo composite index (customerId, createdAt).');
      }
      myJobs = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createJob(Job job) async {
    isLoading = true;
    notifyListeners();

    final result = await _jobService.createJobAndGetSuggestions(job);

    if (result['success'] == true) {
      await fetchMyJobs(); // Load lại ngay sau khi tạo đơn mới
    }

    isLoading = false;
    notifyListeners();
    return result['success'] == true;
  }

  // Gọi khi cần refresh (kéo xuống)
  Future<void> refresh() => fetchMyJobs();
}