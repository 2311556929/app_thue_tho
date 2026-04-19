
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:appthuetho/data/csv_knowledge_base.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'rag_service.dart';

class AiService {
  // ✅ Key đúng từ api_keys.dart của bạn (bắt đầu AIzaSy...)
  // Thay bằng key từ: https://makersuite.google.com/app/apikey
  static const String _apiKey = '';

  /// Hàm chính: Chat với Thợ AI - có RAG từ CSV
  static Future<String> chatWithAI(String message, File? imageFile) async {
    try {
      // BƯỚC 1: Lấy RAG context từ CSV (không cần internet)
      final ragContext = await RagService.getContext(message);

      // BƯỚC 2: Build system prompt có context giá
      final systemPrompt = _buildSystemPrompt(ragContext);

      // BƯỚC 3: Gọi Gemini API
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 500,
        ),
      );

      final parts = <Part>[];

      // Đính kèm ảnh nếu có
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }

      final userText = (message.isEmpty && imageFile != null)
          ? 'Phân tích hình ảnh thiết bị này: chẩn đoán lỗi, mức độ nguy hiểm, cách xử lý tạm thời và ước tính chi phí'
          : message;

      parts.add(TextPart('$systemPrompt\n\nKhách hàng hỏi: $userText'));

      final response = await model.generateContent(
        [Content.multi(parts)],
      ).timeout(const Duration(seconds: 15));

      final text = response.text?.trim() ?? '';
      if (text.isEmpty) return _fallbackFromCsv(message);

      return text;

    } on TimeoutException {
      // Timeout → dùng CSV để trả lời
      return _fallbackFromCsv(message);
    } catch (e) {
      print('Lỗi Gemini: $e');
      // Lỗi bất kỳ → dùng CSV để trả lời, không nói "mạng chập chờn"
      return _fallbackFromCsv(message);
    }
  }

  /// Build system prompt chuẩn có RAG context
  static String _buildSystemPrompt(String ragContext) {
    return '''
BẠN LÀ CHUYÊN GIA SỬA CHỮA ĐỒ GIA DỤNG VỚI 20 NĂM KINH NGHIỆM.
Tên: Thợ AI | Phong cách: Thân thiện, chuyên nghiệp

${ragContext.isNotEmpty ? ragContext : ''}

NHIỆM VỤ:
1. Nếu có ẢNH: Phân tích chi tiết, chẩn đoán 2-3 nguyên nhân, so khớp với bảng giá
2. Nếu có MÔ TẢ: Chẩn đoán, hướng dẫn xử lý tạm thời an toàn
3. VỀ GIÁ: Phải dùng khoảng giá từ BẢNG GIÁ trên, không tự bịa
4. AN TOÀN: Lỗi điện/gas → bắt buộc cảnh báo nguy hiểm trước

ĐỊNH DẠNG TRẢ LỜI:
- 3-6 câu ngắn gọn, tiếng Việt thân thiện
- Dùng emoji: 🔧⚡💧❄️✅⚠️
- Luôn kết thúc: "💰 Chi phí dự kiến: [khoảng giá]"

TUYỆT ĐỐI KHÔNG:
- Nói không biết / không thể trả lời
- Bịa giá ngoài bảng giá
- Bỏ qua cảnh báo an toàn
''';
  }

  /// Fallback thông minh từ CSV khi Gemini lỗi
  static Future<String> _fallbackFromCsv(String message) async {
    final results = await CsvKnowledgeBase.search(message);

    if (results.isNotEmpty) {
      final item = results.first;
      final priceStr = CsvKnowledgeBase.formatPrice(
        item['price_min'] as int? ?? 0,
        item['price_max'] as int? ?? 0,
      );
      final warning = item['warning']?.toString() ?? '';
      final hasWarning = warning.isNotEmpty;

      return '''${hasWarning ? '$warning\n\n' : ''}🔧 Dựa vào mô tả, đây có thể là: **${item['fault_name']}**

✅ Làm ngay: ${item['safe_action']}

📋 Triệu chứng: ${item['symptoms']}

💰 Chi phí dự kiến: $priceStr

Gửi thêm ảnh thiết bị để tôi tư vấn chính xác hơn nhé! 📸''';
    }

    // Không match gì cả
    return '''🔧 Tôi cần thêm thông tin để tư vấn chính xác!

Bạn cho tôi biết:
• Thiết bị bị hỏng là gì? (điều hòa, tủ lạnh, điện, nước...)
• Triệu chứng cụ thể ra sao?
• Sự cố xảy ra từ khi nào?

Hoặc gửi ảnh thiết bị cho tôi phân tích nhé! 📸 😊''';
  }

  /// Phân tích ảnh - trả về 3 chẩn đoán ngắn
  static Future<List<String>> analyzeAppliance(File imageFile) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey);

      final prompt = TextPart(
        'Phân tích ảnh thiết bị gia dụng này. '
            'Đưa ra ĐÚNG 3 chẩn đoán ngắn (dưới 8 chữ tiếng Việt mỗi cái). '
            'CỤ THỂ tên lỗi/linh kiện, KHÔNG chung chung. '
            'Trả về JSON array thuần túy:\n'
            '["chẩn đoán 1", "chẩn đoán 2", "chẩn đoán 3"]',
      );

      final bytes = await imageFile.readAsBytes();
      final response = await model.generateContent([
        Content.multi([prompt, DataPart('image/jpeg', bytes)]),
      ]).timeout(const Duration(seconds: 15));

      String text = response.text ?? '[]';
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();

      final decoded = jsonDecode(text) as List;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return ['Kiểm tra nguồn điện', 'Kiểm tra dây kết nối', 'Gọi thợ kiểm tra'];
    }
  }
}