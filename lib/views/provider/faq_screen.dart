import 'package:flutter/material.dart';
import 'chatbot_support_screen.dart'; // Điều chỉnh đường dẫn nếu cần
class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'category': 'Thanh toán',
      'question': 'Làm sao để rút tiền từ ví?',
      'answer': 'Vào mục Ví tiền → Click "Rút tiền" → Nhập số tiền → Xác nhận. '
          'Số tiền sẽ được chuyển vào tài khoản ngân hàng đã liên kết trong 1-3 ngày làm việc.',
    },
    {
      'category': 'Thanh toán',
      'question': 'Tối thiểu rút bao nhiêu tiền?',
      'answer': 'Số tiền rút tối thiểu là 100.000đ. '
          'Để đảm bảo giao dịch nhanh chóng, hãy liên kết tài khoản ngân hàng.',
    },
    {
      'category': 'Đơn hàng',
      'question': 'Làm sao để nhận nhiều đơn hơn?',
      'answer': '1. Bật trạng thái Online thường xuyên\n'
          '2. Cập nhật kỹ năng, dịch vụ đầy đủ\n'
          '3. Hoàn thành đơn đúng hẹn để tăng rating\n'
          '4. Phản hồi khách hàng nhanh chóng',
    },
    {
      'category': 'Đơn hàng',
      'question': 'Khách hàng hủy đơn sau khi tôi nhận thì sao?',
      'answer': 'Nếu khách hủy sau khi bạn đã nhận và di chuyển, bạn sẽ được bồi thường '
          'phí di chuyển. Vui lòng liên hệ hỗ trợ với mã đơn hàng để được xử lý.',
    },
    {
      'category': 'Tài khoản',
      'question': 'Tại sao tài khoản tôi bị khóa?',
      'answer': 'Tài khoản có thể bị khóa do:\n'
          '• Vi phạm chính sách sử dụng\n'
          '• Nhận nhiều khiếu nại từ khách hàng\n'
          '• Hành vi gian lận\n\n'
          'Liên hệ hỗ trợ để được xem xét mở khóa.',
    },
    {
      'category': 'Tài khoản',
      'question': 'Làm sao để nâng cấp rating?',
      'answer': 'Rating được tính dựa trên:\n'
          '• Đánh giá của khách hàng\n'
          '• Tỉ lệ hoàn thành đơn\n'
          '• Thời gian phản hồi\n\n'
          'Luôn làm việc chuyên nghiệp và đúng hẹn.',
    },
    {
      'category': 'Khác',
      'question': 'Tôi gặp sự cố kỹ thuật app thì làm sao?',
      'answer': 'Thử các bước sau:\n'
          '1. Tắt và mở lại app\n'
          '2. Cập nhật app lên phiên bản mới nhất\n'
          '3. Xóa cache và dữ liệu app\n'
          '4. Nếu vẫn lỗi, liên hệ hỗ trợ với mô tả chi tiết',
    },
    {
      'category': 'Khác',
      'question': 'Thời gian hỗ trợ của team là khi nào?',
      'answer': 'Team hỗ trợ làm việc:\n'
          '• Thứ 2 - Chủ nhật: 7:00 - 22:00\n'
          '• Hotline: 1900 xxxx\n'
          '• Email: support@appthuetho.vn\n'
          '• Chat trực tiếp trong app',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Group FAQs by category
    final Map<String, List<Map<String, String>>> groupedFaqs = {};
    for (var faq in _faqs) {
      final category = faq['category']!;
      if (!groupedFaqs.containsKey(category)) {
        groupedFaqs[category] = [];
      }
      groupedFaqs[category]!.add(faq);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Câu hỏi thường gặp'),
        backgroundColor: const Color(0xFF00AEEF),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search hint
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tìm câu trả lời cho vấn đề của bạn',
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // FAQ by category
          ...groupedFaqs.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(entry.key),
                        color: const Color(0xFF00AEEF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ...entry.value.map((faq) => _buildFAQItem(
                  faq['question']!,
                  faq['answer']!,
                )),
                const SizedBox(height: 8),
              ],
            );
          }),

          const SizedBox(height: 16),

          // Contact support
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent,
                  color: Color(0xFF00AEEF),
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Không tìm thấy câu trả lời?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Liên hệ với đội hỗ trợ của chúng tôi',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatbotSupportScreen()),
                    );
                  },
                  icon: const Icon(Icons.headset_mic),
                  label: const Text('Liên hệ hỗ trợ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00AEEF),
                    side: const BorderSide(color: Color(0xFF00AEEF)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Thanh toán':
        return Icons.payment;
      case 'Đơn hàng':
        return Icons.assignment;
      case 'Tài khoản':
        return Icons.account_circle;
      default:
        return Icons.help_outline;
    }
  }
}