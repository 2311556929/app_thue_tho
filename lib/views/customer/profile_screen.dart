// lib/views/customer/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../provider/provider_main_screen.dart';
import 'CustomerOrderHistoryScreen.dart';
import 'SupportScreen.dart';
import 'member_ship_screen.dart';
import 'personal_info_screen.dart';
import 'voucher_screen.dart';
import 'notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── realtime stats từ Firestore ──────────────────────────
  int _completedOrders = 0;
  int _usedTechnicians = 0;
  int _points = 0;
  int _unreadNotif = 0;
  String _memberLevel = 'Bạc';
  String _name = '';
  String _phone = '';
  String _avatar = '';
  String _email = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listenProfile();
    _listenUnread();
  }

  void _listenProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final d = doc.data() ?? {};
      final pts = (d['points'] ?? 0) as int;
      setState(() {
        _name = d['name'] ?? 'Khách hàng';
        _phone = d['phone'] ?? '';
        _avatar = d['avatar'] ?? '';
        _email = d['email'] ?? '';
        _completedOrders = d['completedOrders'] ?? 0;
        _usedTechnicians = d['usedTechnicians'] ?? 0;
        _points = pts;
        _memberLevel = _calcLevel(pts);
        _loading = false;
      });
    });
  }

  void _listenUnread() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _unreadNotif = snap.docs.length);
    });
  }

  String _calcLevel(int pts) {
    if (pts >= 1000) return 'Kim Cương';
    if (pts >= 500) return 'Vàng';
    if (pts >= 200) return 'Bạc';
    return 'Đồng';
  }

  Map<String, dynamic> _levelConfig(String level) {
    switch (level) {
      case 'Kim Cương':
        return {'color': const Color(0xFF00D4FF), 'icon': Icons.diamond, 'next': -1, 'nextPts': 0};
      case 'Vàng':
        return {'color': const Color(0xFFFFC107), 'icon': Icons.star, 'next': 1000, 'nextPts': 1000};
      case 'Bạc':
        return {'color': const Color(0xFF9E9E9E), 'icon': Icons.workspace_premium, 'next': 500, 'nextPts': 500};
      default:
        return {'color': const Color(0xFFCD7F32), 'icon': Icons.emoji_events, 'next': 200, 'nextPts': 200};
    }
  }

  Future<void> _logout() async {
    final ok = await _confirmDialog('Đăng xuất', 'Bạn có chắc muốn đăng xuất?');
    if (ok && mounted) {
      await context.read<AuthController>().logout(context);
    }
  }

  Future<bool> _confirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: Text(title),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00AEEF))));
    }

    final cfg = _levelConfig(_memberLevel);
    final levelColor = cfg['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar với avatar ──────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF00AEEF),
            actions: [
              // Badge thông báo
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationScreen())),
                  ),
                  if (_unreadNotif > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Text('$_unreadNotif',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PersonalInfoScreen())),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00AEEF), Color(0xFF0057B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _avatar.isNotEmpty
                                  ? NetworkImage(_avatar)
                                  : const NetworkImage(
                                  'https://i.pravatar.cc/150'),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: levelColor,
                                shape: BoxShape.circle,
                                border:
                                Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(cfg['icon'] as IconData,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        _phone.isNotEmpty ? _phone : _email,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border:
                          Border.all(color: levelColor.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cfg['icon'] as IconData,
                                color: levelColor, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'Thành viên $_memberLevel • $_points điểm',
                              style: TextStyle(
                                  color: levelColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildStatsRow(),
                if (cfg['next'] != -1) ...[
                  const SizedBox(height: 12),
                  _buildLevelProgress(cfg),
                ],
                const SizedBox(height: 20),
                _buildMenuSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats 3 cards ────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard('$_completedOrders', 'Đơn\nhoàn thành',
              Icons.assignment_turned_in_rounded, Colors.green),
          const SizedBox(width: 10),
          _statCard('$_usedTechnicians', 'Thợ\nđã dùng',
              Icons.engineering_rounded, const Color(0xFF00AEEF)),
          const SizedBox(width: 10),
          _statCard('$_points', 'Điểm\ntích lũy',
              Icons.stars_rounded, const Color(0xFFFFC107)),
        ],
      ),
    );
  }

  Widget _statCard(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(val,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Level progress ────────────────────────────────────────
  Widget _buildLevelProgress(Map<String, dynamic> cfg) {
    final nextPts = cfg['nextPts'] as int;
    final progress = nextPts > 0 ? (_points / nextPts).clamp(0.0, 1.0) : 1.0;
    final levelColor = cfg['color'] as Color;
    final remaining = nextPts - _points;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: levelColor.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tiến độ lên hạng tiếp theo',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700])),
                Text(
                  remaining > 0
                      ? 'Còn $remaining điểm'
                      : 'Đã đạt hạng cao nhất!',
                  style: TextStyle(
                      fontSize: 12,
                      color: levelColor,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: levelColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(levelColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_points điểm',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500])),
                Text('$nextPts điểm',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Menu ─────────────────────────────────────────────────
  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Tài khoản',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
          ),
          _menuGroup([
            _MenuItem(Icons.person_outline_rounded, 'Thông tin cá nhân',
                'Cập nhật tên, SĐT, địa chỉ', const Color(0xFF00AEEF), () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PersonalInfoScreen()));
                }),
            _MenuItem(Icons.local_offer_rounded, 'Voucher & Ưu đãi',
                'Mã giảm giá và khuyến mãi', Colors.orange, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const VoucherScreen()));
                }),
            _MenuItem(Icons.workspace_premium_rounded,
                'Chương trình thành viên', 'Quyền lợi và tích điểm',
                Colors.purple, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MembershipScreen()));
                }),
          ]),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Hoạt động',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
          ),
          _menuGroup([
            _MenuItem(Icons.history_rounded, 'Lịch sử đơn hàng',
                'Xem tất cả đơn đã thực hiện', Colors.blue, () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerOrderHistoryScreen()));
                }),
            _MenuItem(Icons.notifications_outlined, 'Thông báo',
                _unreadNotif > 0 ? '$_unreadNotif chưa đọc' : 'Không có thông báo mới',
                Colors.red, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NotificationScreen()));
                }, badge: _unreadNotif),
            _MenuItem(Icons.support_agent_rounded, 'Phản hồi & Hỗ trợ',
                'Gửi khiếu nại, yêu cầu hỗ trợ', Colors.green, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SupportScreen()));
                }),
          ]),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Khác',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
          ),
          _menuGroup([
            _MenuItem(Icons.swap_horiz_rounded, 'Chuyển sang chế độ Thợ',
                'Đăng ký và nhận đơn với tư cách thợ', const Color(0xFFFF9500),
                    () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProviderMainScreen()));
                }),
            _MenuItem(Icons.logout_rounded, 'Đăng xuất',
                'Thoát khỏi tài khoản', Colors.red, _logout),
          ]),
        ],
      ),
    );
  }

  Widget _menuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildMenuTile(item),
              if (i < items.length - 1)
                Divider(height: 1, indent: 60, color: Colors.grey[100]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuTile(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: item.color == Colors.red
                              ? Colors.red
                              : const Color(0xFF1A1A2E))),
                  Text(item.subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            if (item.badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${item.badge}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[350], size: 20),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int badge;
  const _MenuItem(this.icon, this.title, this.subtitle, this.color, this.onTap,
      {this.badge = 0});
}