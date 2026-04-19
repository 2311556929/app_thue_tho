import 'package:flutter/material.dart';
import 'provider_dashboard.dart';
import 'new_jobs_screen.dart';

// ✅ IMPORT FILE PROFILE CHUẨN
import 'provider_profile_screen_complete.dart';   // Hoặc 'provider_profile_screen.dart' tuỳ tên file bạn đặt

class ProviderMainScreen extends StatefulWidget {
  const ProviderMainScreen({super.key});

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ProviderDashboard(
        onViewNewOrders: () => setState(() => _currentIndex = 1),
      ),
      const NewJobsScreen(),
      // Đã xoá màn hình Chat ở đây
      const ProviderProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // IndexedStack giúp giữ trạng thái màn hình khi chuyển tab
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF00AEEF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Đơn mới'),
          // Đã xoá Tab Chat ở đây
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}