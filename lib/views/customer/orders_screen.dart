import 'dart:math';
import 'package:appthuetho/models/job_model.dart';
import 'package:appthuetho/views/order_tracking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Đơn hàng'),
      ),
      body: user == null
          ? const Center(child: Text('Vui lòng đăng nhập'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('customerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Lỗi: ${snapshot.error}\n\n'
                      'Nếu lỗi là "FAILED_PRECONDITION", cần tạo composite index cho Firestore.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa có đơn hàng nào',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final jobs = snapshot.data!.docs
              .map((doc) => Job.fromJson(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Tab filter (có thể mở rộng sau)
                Row(
                  children: [
                    _buildTab('Tất cả', true),
                    _buildTab('Đang làm', false),
                    _buildTab('Hoàn thành', false),
                    _buildTab('Đã hủy', false),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return _buildOrderCard(context, job);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00AEEF) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Job job) {
    String statusText;
    Color statusColor;
    switch (job.status) {
      case 'pending':
        statusText = 'Chờ thợ nhận';
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusText = 'Đã có thợ';
        statusColor = Colors.blue;
        break;
      case 'in_progress':
        statusText = 'Đang thực hiện';
        statusColor = Colors.purple;
        break;
      case 'completed':
        statusText = 'Hoàn thành';
        statusColor = Colors.green;
        break;
      default:
        statusText = job.status;
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn #${job.id.substring(0, min(8, job.id.length))}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              job.serviceType,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Địa chỉ: ${job.customerAddress}'),
            Text('Người đặt: ${job.customerName}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Giá dự kiến', style: TextStyle(fontSize: 16)),
                Text(
                  '${(job.estimatedPrice ?? 0).toStringAsFixed(0)}đ',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00AEEF)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [

                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(
                            jobId: job.id,
                            isProvider: false,
                          ),
                        ),
                      );
                    },
                    child: const Text('Xem tiến độ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}