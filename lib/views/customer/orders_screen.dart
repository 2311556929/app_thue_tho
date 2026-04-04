import 'package:appthuetho/views/order_tracking_screen.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tab filter
            Row(
              children: [
                _buildTab('Tất cả', true),
                _buildTab('Đang làm', false),
                _buildTab('Hoàn thành', false),
                _buildTab('Đã hủy', false),
              ],
            ),
            const SizedBox(height: 16),
            // Đơn hàng mẫu 1
            _buildOrderCard(
              context: context,
              orderId: 'Đơn hàng #1',
              service: 'Sửa chữa điện',
              technician: 'Nguyễn Văn A',
              date: '25/03/2026',
              time: '14:00',
              status: 'Hoàn thành',
              amount: '210.000đ',
            ),
            const SizedBox(height: 12),
            // Đơn hàng mẫu 2
            _buildOrderCard(
              context: context,
              orderId: 'Đơn hàng #2',
              service: 'Sửa máy giặt',
              technician: 'Trần Thị B',
              date: '24/03/2026',
              time: '09:30',
              status: 'Đang thực hiện',
              amount: '350.000đ',
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
          style: TextStyle(color: isActive ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required String orderId,
    required String service,
    required String technician,
    required String date,
    required String time,
    required String status,
    required String amount,
  }) {
    return Card(
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
                Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'Hoàn thành' ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: TextStyle(color: status == 'Hoàn thành' ? Colors.green : Colors.orange)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(service, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Thợ: $technician'),
            Text('$date  •  $time'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng tiền', style: const TextStyle(fontSize: 16)),
                Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF))),
              ],
            ),
            const SizedBox(height: 12),
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
                      // Mở Order Tracking cho khách hàng
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderTrackingScreen(
                            jobId: orderId,
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