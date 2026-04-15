
import 'package:app_thuetho_provider/views/provider/new_jobs_screen.dart';
import 'package:app_thuetho_provider/views/provider/provider_chat_screen.dart';
import 'package:app_thuetho_provider/views/provider/provider_dashboard.dart';
import 'package:app_thuetho_provider/views/provider/provider_profile_screen.dart';
import 'package:flutter/material.dart';


class ProviderMainScreen extends StatefulWidget {
  const ProviderMainScreen({super.key});

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ProviderDashboard(),
    const NewJobsScreen(),
    const ProviderChatScreen(),
    const ProviderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}