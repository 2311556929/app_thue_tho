import 'package:appthuetho/views/provider/provider_profile_screen.dart'; // Tuỳ chỉnh đúng đường dẫn chứa ProviderProfileService của bạn
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
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Tắt location tracking
      _locationService.stopLocationTracking();

      // Set offline
      // await _profileService.updateOnlineStatus(false);

      // Đăng xuất
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // Navigate to login (implement later)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng xuất')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileData == null) {
      return const Scaffold(
        body: Center(child: Text('Không tải được profile')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Hồ sơ Thợ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00AEEF),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileAndStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 16),
              _buildStatsCards(),
              const SizedBox(height: 16),
              _buildMenuSection(), // Gọi danh sách Menu ở đây
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _profileData!['name'] ?? 'Thợ';
    final avatar = _profileData!['avatar'] ?? 'https://i.pravatar.cc/150';
    final serviceTypes = List<String>.from(_profileData!['serviceTypes'] ?? []);
    final rating = (_profileData!['rating'] ?? 0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(avatar),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            serviceTypes.join(' - '),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber[700], size: 24),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalJobs = _stats!['totalJobs'] ?? 0;
    final completedJobs = _stats!['completedJobs'] ?? 0;
    final totalEarnings = (_stats!['totalEarnings'] ?? 0).toDouble();
    final acceptanceRate = (_stats!['acceptanceRate'] ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Đơn đã nhận',
                  '$totalJobs',
                  Icons.assignment_turned_in,
                  const Color(0xFF00AEEF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Đánh giá',
                  (_stats!['rating'] ?? 0).toStringAsFixed(1),
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Thu nhập tháng',
                  '${(totalEarnings / 1000).toStringAsFixed(0)}k',
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Tỉ lệ nhận',
                  '${acceptanceRate.toStringAsFixed(0)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ ĐÃ THÊM CÁC ĐƯỜNG DẪN ĐIỀU HƯỚNG TỚI CÁC TRANG CẦN THIẾT
  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.history,
            title: 'Lịch sử nhận đơn',
            subtitle: 'Xem các đơn đã hoàn thành',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const JobHistoryScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.wallet,
            title: 'Ví tiền',
            subtitle: 'Quản lý thu nhập, rút tiền',
            color: Colors.green,
            onTap: () {
              // TODO: Tạo file wallet_screen.dart và dẫn link vào đây
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng Ví tiền đang phát triển')));
            },
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.support_agent,
            title: 'Yêu cầu hỗ trợ',
            subtitle: 'Quản lý các ticket hỗ trợ của bạn',
            color: Colors.orange,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Câu hỏi thường gặp',
            subtitle: 'Hướng dẫn sử dụng và FAQ',
            color: Colors.purple,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Đăng xuất',
            subtitle: 'Thoát khỏi tài khoản',
            color: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFF00AEEF)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color ?? const Color(0xFF00AEEF),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}