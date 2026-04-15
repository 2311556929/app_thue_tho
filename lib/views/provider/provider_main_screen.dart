import 'package:appthuetho/views/customer/chat_detail_screen_realtime.dart';
import 'package:flutter/material.dart';
import 'provider_dashboard.dart';
import 'new_jobs_screen.dart';
import '../customer/chat_screen_realtime.dart';

// ✅ IMPORT FILE CHAT VÀ PROFILE CHUẨN
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
      const ChatScreenRealtime(),
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
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}