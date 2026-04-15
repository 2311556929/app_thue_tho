import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Nhớ kiểm tra lại đường dẫn import cho khớp với project của bạn nhé
import '../../controllers/auth_controller.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Lắng nghe thông tin user thật
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Hồ sơ Thợ')
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12')),
            const SizedBox(height: 12),
            // 2. Hiển thị Tên thật
            Text(user?.name ?? 'Tên thợ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Thợ điện - Tủ lạnh - Máy giặt'), // Tạm thời để tĩnh, sau này thêm field service vào Model
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 3. Đơn đã nhận lấy từ completedOrders
                Expanded(child: _buildStat('${user?.completedOrders ?? 0}', 'Đơn đã nhận')),
                // 4. Đánh giá và thu nhập tạm thời để tĩnh
                Expanded(child: _buildStat('4.9', 'Đánh giá')),
                Expanded(child: _buildStat('1.2tr', 'Thu nhập tháng')),
              ],
            ),
            const SizedBox(height: 32),
            _buildMenuItem(Icons.badge, 'Hồ sơ thợ & dịch vụ'),
            _buildMenuItem(Icons.history, 'Lịch sử nhận đơn'),
            _buildMenuItem(Icons.account_balance_wallet, 'Ví tiền'),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () async {
                // 5. SỬA LỖI ĐĂNG XUẤT: Phải gọi .logout(context)
                await context.read<AuthController>().logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF))),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
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