import 'package:appthuetho/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatbotSupportScreen extends StatefulWidget {
  const ChatbotSupportScreen({super.key});

  @override
  State<ChatbotSupportScreen> createState() => _ChatbotSupportScreenState();
}

class _ChatbotSupportScreenState extends State<ChatbotSupportScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Gemini model
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp', // hoặc 'gemini-pro'
      apiKey: ApiKeys.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 500,
      ),
      systemInstruction: Content.text(
        'Bạn là trợ lý hỗ trợ khách hàng cho ứng dụng sửa chữa điện nước AppThuêThợ. '
            'Hãy trả lời ngắn gọn, thân thiện, tập trung vào các vấn đề: tài khoản, đơn hàng, thanh toán, kỹ thuật. '
            'Nếu không biết, hãy đề nghị tạo yêu cầu hỗ trợ.',
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isTyping = true;
    });
    _controller.clear();

    try {
      // Gọi Gemini API
      final content = [Content.text(text)];
      final response = await _model.generateContent(content);
      String reply = response.text ?? 'Xin lỗi, tôi chưa hiểu. Bạn có thể mô tả rõ hơn không?';

      setState(() {
        _messages.add({'text': reply, 'isUser': false});
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'text': 'Có lỗi xảy ra, vui lòng thử lại sau.',
          'isUser': false,
        });
        _isTyping = false;
      });
    }
  }

  // Giao diện giữ nguyên, chỉ thay logic gửi tin nhắn
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot hỗ trợ AI'),
        backgroundColor: const Color(0xFF00AEEF),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF00AEEF) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Chatbot đang trả lời...'),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Nhập câu hỏi...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _sendMessage(value),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00AEEF)),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}