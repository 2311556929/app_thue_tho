import 'package:app_thuetho_customer/controllers/customer_controller.dart';
import 'package:app_thuetho_customer/models/job_model.dart';
import 'package:app_thuetho_customer/views/order_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerController = Provider.of<CustomerController>(context);

    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false, // THÊM DÒNG NÀY ĐỂ ẨN MŨI TÊN
          title: const Text('Đơn hàng')),
      body: customerController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : customerController.myJobs.isEmpty
          ? const Center(
        child: Text(
          'Bạn chưa có đơn hàng nào',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : SingleChildScrollView(
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

            // Danh sách đơn hàng thật từ Controller
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customerController.myJobs.length,
              itemBuilder: (context, index) {
                final Job job = customerController.myJobs[index];
                return _buildOrderCard(context, job);
              },
            ),
          ],
        ),
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
                Text('Đơn #${job.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: job.status == 'completed' ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    job.status == 'completed' ? 'Hoàn thành' : 'Đang xử lý',
                    style: TextStyle(
                      color: job.status == 'completed' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(job.serviceType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Địa chỉ: ${job.customerAddress}'),
            Text('Người đặt: ${job.customerName}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền', style: TextStyle(fontSize: 16)),
                Text(
                  '210.000đ', // Sau này lấy từ backend
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Đánh giá'),
                  ),
                ),
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