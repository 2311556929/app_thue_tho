import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Nhớ kiểm tra lại đường dẫn import cho khớp với project của bạn nhé
import '../../controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Lắng nghe thông tin user thật từ AuthController
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header profile
            const CircleAvatar(radius: 50),
            const SizedBox(height: 12),
            // 2. Hiển thị Tên thật và Số điện thoại thật
            Text(user?.name ?? 'Khách hàng', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text((user?.phone != null && user!.phone.isNotEmpty) ? user.phone : 'Chưa cập nhật SĐT'),
            const SizedBox(height: 24),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 3. Hiển thị thông số thật
                Expanded(child: _buildStat('${user?.completedOrders ?? 0}', 'Đơn hoàn thành')),
                Expanded(child: _buildStat('${user?.usedTechnicians ?? 0}', 'Thợ đã dùng')),
                Expanded(child: _buildStat('${user?.points ?? 0}', 'Điểm tích luỹ')),
              ],
            ),
            const SizedBox(height: 32),

            // Menu
            _buildMenuItem(Icons.person, 'Thông tin cá nhân'),
            _buildMenuItem(Icons.location_on, 'Voucher'),
            _buildMenuItem(Icons.payment, 'Chương trình thành viên'),
            _buildMenuItem(Icons.history, 'Lịch sử đơn hàng'),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () async {
                // 4. SỬA LỖI ĐĂNG XUẤT: Phải gọi .logout(context)
                await context.read<AuthController>().logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      children: [
        Text(number, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF))),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
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