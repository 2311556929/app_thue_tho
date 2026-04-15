import 'package:flutter/material.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chương trình thành viên'),
        backgroundColor: const Color(0xFF00AEEF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current level
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00AEEF), Color(0xFF0077CC)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.star, color: Color(0xFF00AEEF), size: 40),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thành viên Vàng', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Bạn đã tích lũy 450 điểm', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Text('Lv.4', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Quyền lợi thành viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildBenefitItem('Giảm 10% phí dịch vụ cho mọi đơn'),
            _buildBenefitItem('Miễn phí di chuyển trong bán kính 3km'),
            _buildBenefitItem('Ưu tiên nhận thợ 5 sao'),
            _buildBenefitItem('Nhận voucher sinh nhật đặc biệt'),

            const SizedBox(height: 32),
            const Text('Cách tích điểm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Hoàn thành 1 đơn = +10 điểm')),
            const ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Đánh giá thợ = +5 điểm')),
            const ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Giới thiệu bạn bè = +50 điểm')),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return ListTile(
      leading: const Icon(Icons.card_giftcard, color: Color(0xFF00AEEF)),
      title: Text(text),
    );
  }
}