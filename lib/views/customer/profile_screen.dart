import 'package:appthuetho/views/customer/CustomerOrderHistoryScreen.dart';
import 'package:appthuetho/views/customer/SupportScreen.dart';
import 'package:appthuetho/views/customer/member_ship_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import các màn hình mới
            // Phản hồi & Hỗ trợ
import 'personal_info_screen.dart';        // Thông tin cá nhân
import 'voucher_screen.dart';              // Voucher

import '../../controllers/auth_controller.dart';
import '../provider/provider_main_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Hồ sơ'),
        backgroundColor: const Color(0xFF00AEEF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header profile
            const CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://i.pravatar.cc/150')),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'Khách hàng',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              (user?.phone != null && user!.phone.isNotEmpty) ? user.phone : 'Chưa cập nhật SĐT',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildStat('${user?.completedOrders ?? 0}', 'Đơn hoàn thành')),
                Expanded(child: _buildStat('${user?.usedTechnicians ?? 0}', 'Thợ đã dùng')),
                Expanded(child: _buildStat('${user?.points ?? 0}', 'Điểm tích luỹ')),
              ],
            ),
            const SizedBox(height: 32),

            // Menu
            _buildMenuItem(
              icon: Icons.person,
              title: 'Thông tin cá nhân',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen())),
            ),
            _buildMenuItem(
              icon: Icons.local_offer,
              title: 'Voucher',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherScreen())),
            ),
            _buildMenuItem(
              icon: Icons.payment,
              title: 'Chương trình thành viên',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipScreen())),
            ),
            _buildMenuItem(
              icon: Icons.history,
              title: 'Lịch sử đơn hàng',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerOrderHistoryScreen())),
            ),
            _buildMenuItem(  // ← Mục "Phản hồi & Hỗ trợ" mới thêm
              icon: Icons.support_agent,
              title: 'Phản hồi & Hỗ trợ',
              color: Colors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
            ),

            // Chuyển sang chế độ Thợ
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Color(0xFFFF9500)),
              title: const Text('Chuyển sang chế độ Thợ', style: TextStyle(color: Color(0xFFFF9500))),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProviderMainScreen()),
                );
              },
            ),

            // Đăng xuất
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () async {
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}