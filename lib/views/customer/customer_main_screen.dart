// lib/views/customer/customer_main_screen.dart
import 'package:appthuetho/views/customer/feedback_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'ai_screen_updated.dart';
import 'profile_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _idx = 0;
  int _unreadNotif = 0;

  final List<Widget> _screens = const [
    HomeScreen(),       // index 0 - Trang chủ
    OrdersScreen(),     // index 1 - Đơn hàng
    AiScreenComplete(), // index 2 - Thợ AI
    FeedbackScreen(),   // index 3 - Phản Hồi
    ProfileScreen(),    // index 4 - Hồ sơ
  ];

  @override
  void initState() {
    super.initState();
    _listenUnread();
  }

  void _listenUnread() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Lắng nghe badge thông báo chưa đọc
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _idx,
        children: _screens,
      ),
      bottomNavigationBar: _buildBeautifulNav(),
    );
  }

  Widget _buildBeautifulNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 75, // Cố định chiều cao để chống nhảy layout
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                iconActive: Icons.home_rounded,
                label: 'Trang chủ',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.receipt_long_outlined,
                iconActive: Icons.receipt_long_rounded,
                label: 'Đơn hàng',
              ),
              _buildAITab(), // Tab giữa đặc biệt
              _buildNavItem(
                index: 3,
                icon: Icons.feedback_outlined,
                iconActive: Icons.feedback_rounded,
                label: 'Phản hồi',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                iconActive: Icons.person_rounded,
                label: 'Hồ sơ',
                badge: _unreadNotif,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Đã gộp hàm có badge và không badge làm một để code gọn hơn
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData iconActive,
    required String label,
    int badge = 0,
  }) {
    final bool selected = _idx == index;
    // Dùng Expanded để chia đều không gian, dứt điểm lỗi sọc đen vàng
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _idx = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  // Giảm padding ngang một chút để các item không đụng nhau
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF00AEEF).withOpacity(0.13)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    selected ? iconActive : icon,
                    color: selected ? const Color(0xFF00AEEF) : Colors.grey[500],
                    size: 24,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: 0,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 17, minHeight: 17),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1, // Tránh chữ bị xuống dòng làm vỡ khung
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? const Color(0xFF00AEEF) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab AI nổi bật ở giữa
  Widget _buildAITab() {
    final bool selected = _idx == 2;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _idx = 2),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              // Giảm một chút size để cân đối với 4 nút còn lại
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                  colors: [Color(0xFF00AEEF), Color(0xFF0057B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : const LinearGradient(
                  colors: [Color(0xFFD6F0FF), Color(0xFFBDE5FF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: const Color(0xFF00AEEF).withOpacity(0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
                    : [],
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: selected ? Colors.white : const Color(0xFF00AEEF),
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Thợ AI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? const Color(0xFF00AEEF) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}