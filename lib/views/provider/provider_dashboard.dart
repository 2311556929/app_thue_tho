import 'package:flutter/material.dart';

class ProviderDashboard extends StatelessWidget {
  const ProviderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xin chào, Thợ A')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Hôm nay', style: TextStyle(fontSize: 18)),
                    Text('3 đơn mới gần bạn', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Sẵn sàng nhận đơn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text('Tôi đang online'),
              value: true,
              onChanged: (val) {},
              activeColor: const Color(0xFF00AEEF),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.notifications),
              label: const Text('Xem đơn mới ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9500),
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: () {
                // Sau này chuyển sang NewJobsScreen
              },
            ),
          ],
        ),
      ),
    );
  }
}