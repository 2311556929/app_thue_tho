import 'package:appthuetho/views/provider/provider_main_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header profile
            const CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5')),
            const SizedBox(height: 12),
            const Text('Khách hàng', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('0912 345 678'),
            const SizedBox(height: 24),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('12', 'Đơn hoàn thành'),
                _buildStat('8', 'Thợ đã dùng'),
                _buildStat('450', 'Điểm tích lũy'),
              ],
            ),
            const SizedBox(height: 32),

            // Menu
            _buildMenuItem(Icons.person, 'Thông tin cá nhân'),
            _buildMenuItem(Icons.location_on, 'Địa chỉ đã lưu'),
            _buildMenuItem(Icons.payment, 'Phương thức thanh toán'),
            _buildMenuItem(Icons.history, 'Lịch sử đơn hàng'),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Color(0xFFFF9500)),
              title: const Text('Chuyển sang chế độ Thợ', style: TextStyle(color: Color(0xFFFF9500))),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProviderMainScreen()),
                );
              },
            ),
            const Divider(),
            _buildMenuItem(Icons.logout, 'Đăng xuất', color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      children: [
        Text(number, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF))),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {Color color = Colors.black87}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}