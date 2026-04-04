import 'package:appthuetho/services/job_service.dart';
import 'package:appthuetho/views/order_tracking_screen.dart';
import 'package:flutter/material.dart';

class NewJobsScreen extends StatefulWidget {
  const NewJobsScreen({super.key});

  @override
  State<NewJobsScreen> createState() => _NewJobsScreenState();
}

class _NewJobsScreenState extends State<NewJobsScreen> {
  List<dynamic> pendingJobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingJobs();
  }

  Future<void> _loadPendingJobs() async {
    final jobService = JobService();
    final jobs = await jobService.getPendingJobs();
    setState(() {
      pendingJobs = jobs;
      isLoading = false;
    });
  }

  Future<void> _acceptJob(String jobId) async {
    final jobService = JobService();
    bool success = await jobService.acceptJob(jobId, 'tech_001'); // sau thay ID thật
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã nhận đơn thành công!')),
      );
      // Tự động chuyển sang theo dõi tiến độ
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderTrackingScreen(
            jobId: jobId,
            isProvider: true,   // Thợ có nút "Tiếp theo"
          ),
        ),
      );
      _loadPendingJobs(); // tải lại danh sách
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn mới gần bạn')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingJobs.isEmpty
          ? const Center(child: Text('Hiện chưa có đơn mới nào'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingJobs.length,
        itemBuilder: (context, index) {
          final job = pendingJobs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(job['serviceType'] ?? 'Sửa chữa', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${job['description']}\n📍 ${job['latitude']?.toStringAsFixed(4)}, ${job['longitude']?.toStringAsFixed(4)}'),
              trailing: ElevatedButton(
                onPressed: () => _acceptJob(job['id']),
                child: const Text('Nhận đơn'),
              ),
            ),
          );
        },
      ),
    );
  }
}