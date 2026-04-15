import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../order_tracking_screen.dart';

class CustomerOrderHistoryScreen extends StatelessWidget {
  const CustomerOrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử đơn hàng')),
      body: userId == null
          ? const Center(child: Text('Vui lòng đăng nhập'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('customerId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có đơn hàng nào'));
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final data = jobs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? '';
              final isCompleted = status == 'completed';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đơn #${jobs[index].id.substring(0, 8)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['serviceType'] ?? 'Dịch vụ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Địa chỉ: ${data['customerAddress'] ?? ''}'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderTrackingScreen(
                                      jobId: jobs[index].id,
                                      isProvider: false,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Xem tiến độ'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isCompleted)
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () => _showWarrantyDialog(context, jobs[index].id, data),
                                child: const Text('Bảo hành', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    String text;
    Color color;
    switch (status) {
      case 'completed':
        text = 'Hoàn thành';
        color = Colors.green;
        break;
      case 'in_progress':
        text = 'Đang làm';
        color = Colors.orange;
        break;
      case 'accepted':
        text = 'Đã có thợ';
        color = Colors.blue;
        break;
      default:
        text = 'Chờ thợ';
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
    );
  }

  void _showWarrantyDialog(BuildContext context, String jobId, Map<String, dynamic> jobData) {
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu bảo hành'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Đơn: ${jobData['serviceType'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Mô tả vấn đề cần bảo hành (hỏng lại, lỗi cũ...)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId == null || descController.text.trim().isEmpty) return;

              await FirebaseFirestore.instance.collection('warranty_requests').add({
                'jobId': jobId,
                'customerId': userId,
                'serviceType': jobData['serviceType'],
                'description': descController.text.trim(),
                'status': 'pending',
                'createdAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Yêu cầu bảo hành đã được gửi! Chúng tôi sẽ liên hệ sớm.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }
}