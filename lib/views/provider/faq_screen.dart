import 'package:flutter/material.dart';
import 'chatbot_support_screen.dart'; // Điều chỉnh đường dẫn nếu cần

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Lọc FAQ dựa trên từ khóa tìm kiếm
    final filteredFaqs = _faqs.where((faq) {
      final question = faq['question']!.toLowerCase();
      final answer = faq['answer']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return question.contains(query) || answer.contains(query);
    }).toList();

    // 2. Nhóm FAQ đã lọc theo danh mục
    final Map<String, List<Map<String, String>>> groupedFaqs = {};
    for (var faq in filteredFaqs) {
      final category = faq['category']!;
      if (!groupedFaqs.containsKey(category)) {
        groupedFaqs[category] = [];
      }
      groupedFaqs[category]!.add(faq);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Câu hỏi thường gặp',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Ẩn bàn phím khi bấm ra ngoài
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            // Tiêu đề chào mừng
            Text(
              'Chúng tôi có thể\ngiúp gì cho bạn?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.blue.shade900, height: 1.2),
            ),
            const SizedBox(height: 24),

            // Thanh tìm kiếm
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Nhập từ khóa cần tìm...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00AEEF)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Hiển thị nội dung
            if (groupedFaqs.isEmpty)
              _buildEmptyState()
            else
              ...groupedFaqs.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề danh mục
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00AEEF).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_getCategoryIcon(entry.key), color: const Color(0xFF00AEEF), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            entry.key,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                    ),

                    // Danh sách câu hỏi trong danh mục
                    ...entry.value.map((faq) => _buildFAQItem(faq['question']!, faq['answer']!)),
                    const SizedBox(height: 16),
                  ],
                );
              }),

            const SizedBox(height: 24),
            _buildSupportBanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Khung trống khi tìm kiếm không ra kết quả
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm bằng từ khóa khác hoặc\nliên hệ trực tiếp với chúng tôi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // Khối ExpansionTile tùy chỉnh
  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent), // Xóa dòng kẻ mặc định
        child: ExpansionTile(
          iconColor: const Color(0xFF00AEEF),
          collapsedIconColor: Colors.grey.shade500,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          title: Text(
            question,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
          children: [
            const Divider(height: 16, thickness: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: TextStyle(color: Colors.grey.shade600, height: 1.6, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Banner liên hệ hỗ trợ AI xịn xò
  Widget _buildSupportBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00AEEF), Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00AEEF).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Vẫn cần trợ giúp?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Chat trực tiếp với Trợ lý AI hoặc tổng đài viên để được giải quyết vấn đề nhanh nhất.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotSupportScreen()),
                );
              },
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.blue.shade700),
              label: Text('Chat với Hỗ trợ ngay', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Thanh toán':
        return Icons.account_balance_wallet_rounded;
      case 'Đơn hàng':
        return Icons.assignment_rounded;
      case 'Tài khoản':
        return Icons.manage_accounts_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}