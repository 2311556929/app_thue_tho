import 'package:appthuetho/views/provider/creat_ticket_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_tickets_screen.dart';
import 'faq_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Hỗ trợ & Phản hồi'),
        backgroundColor: const Color(0xFF00AEEF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00AEEF), Color(0xFF0086c3)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.support_agent, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chúng tôi luôn sẵn sàng hỗ trợ bạn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thời gian hỗ trợ: 7:00 - 22:00 hàng ngày',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Hành động nhanh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildQuickAction(
              context,
              icon: Icons.add_circle_outline,
              title: 'Tạo yêu cầu hỗ trợ',
              subtitle: 'Báo cáo vấn đề, khiếu nại',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateTicketScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _buildQuickAction(
              context,
              icon: Icons.receipt_long,
              title: 'Yêu cầu của tôi',
              subtitle: 'Xem trạng thái xử lý',
              color: const Color(0xFF00AEEF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyTicketsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _buildQuickAction(
              context,
              icon: Icons.help_outline,
              title: 'Câu hỏi thường gặp',
              subtitle: 'Tìm câu trả lời nhanh chóng',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FAQScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Contact Methods
            const Text(
              'Liên hệ trực tiếp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildContactTile(
                    icon: Icons.phone,
                    title: 'Hotline',
                    subtitle: '1900 xxxx',
                    color: Colors.green,
                    onTap: () {
                      // Call hotline
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _buildContactTile(
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: 'support@appthuetho.vn',
                    color: Colors.blue,
                    onTap: () {
                      // Send email
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _buildContactTile(
                    icon: Icons.chat,
                    title: 'Chat trực tiếp',
                    subtitle: 'Phản hồi trong 5 phút',
                    color: const Color(0xFF00AEEF),
                    onTap: () {
                      // Open live chat
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Lưu ý',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Cung cấp đầy đủ thông tin để được hỗ trợ nhanh\n'
                        '• Đính kèm ảnh/video nếu cần thiết\n'
                        '• Thời gian xử lý: 24-48 giờ làm việc\n'
                        '• Khiếu nại khẩn cấp sẽ được ưu tiên',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}