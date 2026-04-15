import 'package:appthuetho/models/job_model.dart';
import 'package:appthuetho/services/job_service.dart';
import 'package:flutter/material.dart';

class ProviderController with ChangeNotifier {
  final JobService _jobService = JobService();
  List<Job> pendingJobs = [];
  bool isLoading = false;

  Future<void> loadPendingJobs() async {
    isLoading = true;
    notifyListeners();

    pendingJobs = await _jobService.getPendingJobs();

    isLoading = false;
    notifyListeners();
  }

  Future<bool> acceptJob(String jobId) async {
    final success = await _jobService.acceptJob(jobId, 'tech_001');
    if (success) await loadPendingJobs();
    return success;
  }
}