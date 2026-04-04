import 'package:appthuetho/views/customer/post_job_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xin chào, Khách hàng'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm dịch vụ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            // Địa chỉ
            const Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF00AEEF)),
                SizedBox(width: 8),
                Text('123 Nguyễn Huệ, Q.1, TP.HCM'),
              ],
            ),
            const SizedBox(height: 24),
            // Nút Đăng yêu cầu sửa ngay
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.build),
                label: const Text('Đăng yêu cầu sửa ngay', style: TextStyle(fontSize: 18)),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PostJobScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            const Text('Dịch vụ phổ biến', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // 4 icon dịch vụ (như ảnh)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildServiceIcon(Icons.build, 'Sửa chữa'),
                _buildServiceIcon(Icons.water_drop, 'Thợ nước'),
                _buildServiceIcon(Icons.electric_bolt, 'Thợ điện'),
                _buildServiceIcon(Icons.air, 'Điều hòa'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcon(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(radius: 30, backgroundColor: Colors.grey[200], child: Icon(icon, size: 32, color: const Color(0xFF00AEEF))),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}