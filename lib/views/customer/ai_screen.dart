import 'package:flutter/material.dart';

class AIScreen extends StatelessWidget {
  const AIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Gợi ý thợ')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 120, color: Color(0xFF00AEEF)),
            SizedBox(height: 24),
            Text(
              'AI đang tìm thợ phù hợp nhất cho bạn...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Chỉ mất vài giây', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 48),
            CircularProgressIndicator(color: Color(0xFF00AEEF)),
          ],
        ),
      ),
    );
  }
}