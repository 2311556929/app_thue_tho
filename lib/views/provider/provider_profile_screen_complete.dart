import 'package:appthuetho/views/customer/customer_main_screen.dart';
import 'package:appthuetho/views/provider/provider_profile_screen.dart'; // Tuỳ chỉnh đúng đường dẫn chứa ProviderProfileService của bạn
import 'package:appthuetho/views/provider/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'job_history_screen.dart';
import 'faq_screen.dart';
import 'my_tickets_screen.dart';
// import 'wallet_screen.dart'; // Nếu bạn đã có file ví tiền thì import ở đây

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final ProviderProfileService _profileService = ProviderProfileService();
  final LocationService _locationService = LocationService();

  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndStats();
  }

  Future<void> _loadProfileAndStats() async {
    setState(() => _isLoading = true);

    final profile = await _profileService.getProviderProfile();
    final stats = await _profileService.getProviderStats();

    setState(() {
      _profileData = profile;
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản thợ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _locationService.stopLocationTracking();
      // await _profileService.updateOnlineStatus(false);
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng xuất thành công')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00AEEF);
    const Color bgColor = Color(0xFFF9FAFB);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (_profileData == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: Text('Không tải được thông tin hồ sơ', style: TextStyle(color: Colors.grey))),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _loadProfileAndStats,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // --- APPBAR NỔI BẬT ---
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Hồ sơ của tôi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                centerTitle: true,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00AEEF), Color(0xFF0090D6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_square, color: Colors.white),
                  onPressed: () {
                    // TODO: Navigate to edit profile
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Dải nền xanh kéo dài xuống một chút
                  Container(
                    height: 80,
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                  ),

                  // Nội dung chính nằm đè lên nền xanh
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildProfileHeaderCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Thống kê hoạt động'),
                        _buildStatsDashboard(),
                        const SizedBox(height: 24),
                        _buildMenuSections(),
                        const SizedBox(height: 100), // Spacing for bottom nav
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD THÔNG TIN CÁ NHÂN CHÍNH ---
  Widget _buildProfileHeaderCard() {
    final name = _profileData!['name'] ?? 'Thợ';
    final avatar = _profileData!['avatar'] ?? 'https://i.pravatar.cc/150';
    final serviceTypes = List<String>.from(_profileData!['serviceTypes'] ?? []);
    final rating = (_profileData!['rating'] ?? 0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar có viền
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0F2FE), width: 3),
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundImage: NetworkImage(avatar),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(height: 16),

          // Tên
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 6),

          // Dịch vụ cung cấp (Chips)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: serviceTypes.isEmpty
                ? [const Text('Chưa cập nhật dịch vụ', style: TextStyle(color: Colors.grey))]
                : serviceTypes.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(s, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
          const SizedBox(height: 16),

          // Rating Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 22),
                const SizedBox(width: 6),
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                ),
                const SizedBox(width: 4),
                Text('/ 5.0', style: TextStyle(fontSize: 14, color: Colors.amber.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET TIÊU ĐỀ SECTION ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
        ),
      ),
    );
  }

  // --- DASHBOARD THỐNG KÊ ---
  Widget _buildStatsDashboard() {
    final totalJobs = _stats!['totalJobs'] ?? 0;
    final totalEarnings = (_stats!['totalEarnings'] ?? 0).toDouble();
    final acceptanceRate = (_stats!['acceptanceRate'] ?? 0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDashboardCard('Đơn hoàn thành', '$totalJobs', Icons.check_circle_outline, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildDashboardCard('Thu nhập (tháng)', '${(totalEarnings / 1000).toStringAsFixed(0)}k', Icons.account_balance_wallet_outlined, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDashboardCard('Tỉ lệ nhận đơn', '${acceptanceRate.toStringAsFixed(0)}%', Icons.pie_chart_outline, Colors.purple)),
            const SizedBox(width: 12),
            Expanded(child: _buildDashboardCard('Cấp bậc', 'Bạc', Icons.military_tech_outlined, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardCard(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
        border: Border.all(color: color.shade50, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.shade50, shape: BoxShape.circle),
            child: Icon(icon, color: color.shade600, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color.shade800)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- MENU GOM NHÓM HIỆN ĐẠI ---
  Widget _buildMenuSections() {
    return Column(
      children: [
        _buildSectionTitle('Quản lý công việc'),
        _buildMenuGroup([
          _buildGroupedMenuItem(
            icon: Icons.history_rounded, color: Colors.blue,
            title: 'Lịch sử nhận đơn', subtitle: 'Xem lại các đơn đã hoàn thành',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobHistoryScreen())),
          ),
          _buildDivider(),
          _buildGroupedMenuItem(
            icon: Icons.account_balance_wallet_rounded, color: Colors.green,
            title: 'Ví tiền', subtitle: 'Quản lý doanh thu & Rút tiền',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionTitle('Hỗ trợ & Công cụ'),
        _buildMenuGroup([
          _buildGroupedMenuItem(
            icon: Icons.headset_mic_rounded, color: Colors.orange,
            title: 'Trung tâm hỗ trợ', subtitle: 'Giải đáp thắc mắc, khiếu nại',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen())),
          ),
          _buildDivider(),
          _buildGroupedMenuItem(
            icon: Icons.help_outline_rounded, color: Colors.purple,
            title: 'Câu hỏi thường gặp (FAQ)', subtitle: 'Hướng dẫn sử dụng ứng dụng',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQScreen())),
          ),
          _buildDivider(),
          _buildGroupedMenuItem(
            icon: Icons.swap_horiz_rounded, color: Colors.amber.shade600,
            title: 'Chuyển sang Khách hàng', subtitle: 'Trải nghiệm app với vai trò khách',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerMainScreen())),
          ),
        ]),
        const SizedBox(height: 24),

        _buildMenuGroup([
          _buildGroupedMenuItem(
            icon: Icons.logout_rounded, color: Colors.red,
            title: 'Đăng xuất', subtitle: 'Thoát tài khoản khỏi thiết bị này',
            onTap: _logout,
            isDestructive: true,
          ),
        ]),
      ],
    );
  }

  // Khung viền bọc nhóm menu
  Widget _buildMenuGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  // Dòng kẻ ngăn cách giữa các item trong nhóm
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 16), // Thụt lề để không đè lên icon
      child: Divider(height: 1, color: Colors.grey.shade100, thickness: 1),
    );
  }

  // Item menu được tối ưu lại để dùng chung viền của nhóm
  Widget _buildGroupedMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20), // Đảm bảo hiệu ứng chạm bo góc đúng
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive ? color.withOpacity(0.1) : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDestructive ? Colors.red.shade700 : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}