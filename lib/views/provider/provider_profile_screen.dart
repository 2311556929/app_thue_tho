import 'package:appthuetho/views/customer/customer_main_screen.dart';
import 'package:flutter/material.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ Thợ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12')),
            const SizedBox(height: 12),
            const Text('Nguyễn Văn A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Thợ điện - Tủ lạnh - Máy giặt'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('28', 'Đơn đã nhận'),
                _buildStat('4.9', 'Đánh giá'),
                _buildStat('1.2tr', 'Thu nhập tháng'),
              ],
            ),
            const SizedBox(height: 32),
            _buildMenuItem(Icons.badge, 'Hồ sơ thợ & dịch vụ'),
            _buildMenuItem(Icons.history, 'Lịch sử nhận đơn'),
            _buildMenuItem(Icons.account_balance_wallet, 'Ví tiền'),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Color(0xFF00AEEF)),
              title: const Text('Chuyển sang chế độ Khách hàng'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerMainScreen()),
                );
              },
            ),
            const Divider(),
            _buildMenuItem(Icons.logout, 'Đăng xuất', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF))),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, [Color color = Colors.black87]) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}