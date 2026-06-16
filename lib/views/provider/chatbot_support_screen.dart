import 'package:appthuetho/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:math' as math;

class ChatbotSupportScreen extends StatefulWidget {
  const ChatbotSupportScreen({super.key});

  @override
  State<ChatbotSupportScreen> createState() => _ChatbotSupportScreenState();
}

class _ChatbotSupportScreenState extends State<ChatbotSupportScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  late GenerativeModel _model;

  // Gợi ý nhanh cho người dùng
  final List<String> _quickReplies = [
    'Làm sao để đặt lịch?',
    'Chính sách bảo hành',
    'Hình thức thanh toán',
    'Phí dịch vụ tính thế nào?'
  ];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-pro', // hoặc 'gemini-pro'
      apiKey: ApiKeys.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 500,
      ),
      systemInstruction: Content.text(
        'Bạn là trợ lý hỗ trợ khách hàng chuyên nghiệp, tận tâm cho ứng dụng sửa chữa điện nước AppThuêThợ. '
            'Hãy trả lời ngắn gọn, thân thiện, lịch sự, tập trung vào các vấn đề: tài khoản, đơn hàng, thanh toán, kỹ thuật. '
            'Nếu không biết, hãy đề nghị khách hàng tạo yêu cầu hỗ trợ qua mục "Yêu cầu của tôi". Tránh trả lời dài dòng.',
      ),
    );

    // Lời chào ban đầu
    _messages.add({
      'text': 'Xin chào! 👋 Tôi là trợ lý AI của AppThuêThợ.\nTôi có thể giúp gì cho bạn hôm nay?',
      'isUser': false,
      'time': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isUser': true, 'time': DateTime.now()});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();
    FocusScope.of(context).unfocus(); // Ẩn bàn phím khi gửi

    try {
      final content = [Content.text(text)];
      final response = await _model.generateContent(content);
      String reply = response.text ?? 'Xin lỗi, tôi chưa hiểu rõ ý của bạn. Bạn có thể mô tả chi tiết hơn được không?';

      if (mounted) {
        setState(() {
          _messages.add({'text': reply, 'isUser': false, 'time': DateTime.now()});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': 'Hệ thống đang quá tải hoặc lỗi mạng. Vui lòng thử lại sau nhé! 😓',
            'isUser': false,
            'time': DateTime.now(),
          });
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00AEEF);
    const Color bgColor = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(primaryColor),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.length == 1
                  ? _buildEmptyState() // Chỉ có lời chào -> hiện gợi ý
                  : _buildMessageList(primaryColor),
            ),

            if (_isTyping) _buildTypingIndicator(),

            _buildInputArea(primaryColor),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: APPBAR ---
  PreferredSizeWidget _buildAppBar(Color primaryColor) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.smart_toy_rounded, color: primaryColor, size: 22),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Trợ lý AI',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Luôn sẵn sàng hỗ trợ',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  // --- WIDGET: MÀN HÌNH CHÀO MỪNG + GỢI Ý ---
  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        _buildMessageBubble(_messages[0], const Color(0xFF00AEEF)),
        const SizedBox(height: 30),
        Text(
          'Gợi ý cho bạn:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _quickReplies.map((reply) => ActionChip(
            label: Text(reply),
            labelStyle: TextStyle(color: const Color(0xFF00AEEF).withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
            backgroundColor: Colors.white,
            side: BorderSide(color: const Color(0xFF00AEEF).withOpacity(0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _sendMessage(reply),
          )).toList(),
        ),
      ],
    );
  }

  // --- WIDGET: DANH SÁCH TIN NHẮN ---
  Widget _buildMessageList(Color primaryColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index], primaryColor);
      },
    );
  }

  // --- WIDGET: BONG BÓNG TIN NHẮN ---
  Widget _buildMessageBubble(Map<String, dynamic> msg, Color primaryColor) {
    final isUser = msg['isUser'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.smart_toy_rounded, color: primaryColor, size: 18),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                msg['text'],
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),

          if (isUser) const SizedBox(width: 32), // Spacer để tin nhắn user không dính sát viền nếu có avatar
        ],
      ),
    );
  }

  // --- WIDGET: HIỆU ỨNG ĐANG GÕ (TYPING) ---
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.smart_toy_rounded, color: Colors.grey.shade500, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: const _TypingDots(), // Gọi widget 3 dấu chấm nhảy
          ),
        ],
      ),
    );
  }

  // --- WIDGET: KHUNG NHẬP LIỆU ---
  Widget _buildInputArea(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) => _sendMessage(value),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Nhập câu hỏi của bạn...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nút gửi có Animation
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// WIDGET BỔ TRỢ: HIỆU ỨNG 3 DẤU CHẤM NHẢY (TYPING ANIMATION)
// =========================================================================
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Tạo độ trễ (delay) cho từng chấm
            double delay = index * 0.2;
            double value = math.sin((_controller.value - delay) * 2 * math.pi);
            double yOffset = value < 0 ? value * 5 : 0; // Chỉ nảy lên trên

            return Transform.translate(
              offset: Offset(0, yOffset),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}