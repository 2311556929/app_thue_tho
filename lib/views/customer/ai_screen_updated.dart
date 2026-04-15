import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_service_updated.dart';

// Model để lưu trữ tin nhắn
class ChatMessage {
  final String text;
  final bool isUser;
  final File? image;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.image,
  }) : timestamp = DateTime.now();
}

class AiScreenComplete extends StatefulWidget {
  const AiScreenComplete({super.key});

  @override
  State<AiScreenComplete> createState() => _AiScreenCompleteState();
}

class _AiScreenCompleteState extends State<AiScreenComplete> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Lời chào ban đầu từ AI - CHỈ 1 LẦN
    _messages.add(ChatMessage(
      text: "👋 Xin chào! Tôi là **Thợ AI** với 20 năm kinh nghiệm.\n\n"
          "🔧 Tôi có thể giúp bạn:\n"
          "• Chẩn đoán lỗi từ ảnh\n"
          "• Tư vấn cách sửa tạm thời\n"
          "• Ước tính chi phí sửa chữa\n\n"
          "Bạn đang gặp vấn đề gì? Gửi ảnh hoặc mô tả cho tôi nhé! 😊",
      isUser: false,
    ));
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _sendMessage() async {
    String text = _textController.text.trim();
    File? imageToSend = _selectedImage;

    if (text.isEmpty && imageToSend == null) return;

    // Thêm tin nhắn của User
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        image: imageToSend,
      ));
      _isLoading = true;
      _textController.clear();
      _selectedImage = null;
    });

    _scrollToBottom();

    try {
      // Gọi AI
      String aiResponse = await AiService.chatWithAI(text, imageToSend);

      // Kiểm tra response rỗng hoặc lỗi
      if (aiResponse.isEmpty || aiResponse.contains('Xin lỗi')) {
        aiResponse = "🔧 Tôi đã xem vấn đề của bạn rồi!\n\n"
            "Để tư vấn chính xác hơn, bạn có thể:\n"
            "• Chụp ảnh thiết bị gần hơn\n"
            "• Mô tả cụ thể triệu chứng (kêu to, không chạy, chảy nước...)\n"
            "• Cho biết loại thiết bị (tủ lạnh, máy giặt, điều hòa...)\n\n"
            "Tôi sẽ tư vấn ngay! 😊";
      }

      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: "⚠️ Đã có lỗi xảy ra. Vui lòng thử lại!",
          isUser: false,
        ));
      });
      print('Lỗi AI: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Thợ AI - Chuyên Gia Sửa Chữa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00AEEF),
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Về Thợ AI'),
                  content: const Text(
                    'Tôi là trợ lý AI với 20 năm kinh nghiệm sửa chữa.\n\n'
                        '✅ Chẩn đoán lỗi từ ảnh\n'
                        '✅ Tư vấn cách sửa\n'
                        '✅ Ước tính chi phí\n'
                        '✅ Hỗ trợ 24/7\n\n'
                        'Hãy gửi ảnh hoặc mô tả vấn đề để được tư vấn miễn phí!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Clear chat
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa lịch sử chat?'),
                  content: const Text('Tất cả tin nhắn sẽ bị xóa'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _messages.clear();
                          _messages.add(ChatMessage(
                            text: "👋 Tôi đã sẵn sàng! Bạn cần tư vấn gì?",
                            isUser: false,
                          ));
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner hướng dẫn
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.cyan[50]!],
              ),
              border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '💡 Chụp ảnh thiết bị để được chẩn đoán chính xác nhất',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Khu vực hiển thị tin nhắn
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),

          // Hiển thị AI đang gõ
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue[600]),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Thợ AI đang phân tích...',
                        style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Khu vực Input
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF00AEEF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 20),
          ),
          boxShadow: [
            if (!message.isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(message.image!, fit: BoxFit.cover),
                ),
              ),
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedImage != null)
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(color: const Color(0xFF00AEEF), width: 2),
                  ),
                ),
                Positioned(
                  right: -8,
                  top: -8,
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                )
              ],
            ),

          Row(
            children: [
              IconButton(
                icon: Icon(Icons.image, color: Colors.blue[600]),
                onPressed: () => _pickImage(ImageSource.gallery),
                tooltip: 'Chọn ảnh',
              ),
              IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.green[600]),
                onPressed: () => _pickImage(ImageSource.camera),
                tooltip: 'Chụp ảnh',
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Mô tả vấn đề của bạn...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF00AEEF),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 22),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}