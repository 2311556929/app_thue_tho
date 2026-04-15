import 'package:app_thuetho_customer/models/job_model.dart';
import 'package:app_thuetho_customer/services/job_service.dart';
import 'package:flutter/material.dart';


class CustomerController with ChangeNotifier {
  final JobService _jobService = JobService();
  List<Job> myJobs = [];
  bool isLoading = false;

  Future<bool> createJob(Job job) async {
    isLoading = true;
    notifyListeners();

    final result = await _jobService.createJobAndGetSuggestions(job);
    isLoading = false;
    notifyListeners();

    return result['success'] == true;
  }
}