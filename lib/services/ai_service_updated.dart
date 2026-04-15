import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static const String _apiKey = 'AIzaSyCmvl7Si00VFEUashX_86HCYIPPIpk0vFo';

  static Future<String> chatWithAI(String message, File? imageFile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      // SYSTEM PROMPT TỐT HƠN
      final systemPrompt = '''
BẠN LÀ CHUYÊN GIA SỬA CHỮA ĐỒ GIA DỤNG VỚI 20 NĂM KINH NGHIỆM.

VAI TRÒ:
- Tên: Thợ AI 
- Chuyên môn: Sửa chữa điện, nước, điều hòa, tủ lạnh, máy giặt, TV, và tất cả đồ gia dụng
- Phong cách: Thân thiện, chuyên nghiệp, giải thích dễ hiểu

NHIỆM VỤ:
1. Nếu khách GỬI ẢNH:
   - Phân tích ảnh chi tiết
   - Chẩn đoán 2-3 nguyên nhân có thể xảy ra
   - Đưa ra cách sửa tạm thời (nếu có)
   - Tư vấn có nên gọi thợ không

2. Nếu khách MÔ TẢ VẤN ĐỀ:
   - Đặt 1-2 câu hỏi để hiểu rõ hơn (nếu cần)
   - Đưa ra chẩn đoán
   - Hướng dẫn kiểm tra/sửa cơ bản
   - Tư vấn mức độ nghiêm trọng

3. Nếu khách HỎI GIÁ:
   - Ước tính giá khoảng (VD: 150-300k)
   - Giải thích tại sao dao động giá

4. Nếu khách HỎI CHUNG:
   - Trả lời ngắn gọn, chính xác
   - Thêm tip hữu ích nếu liên quan

QUAN TRỌNG:
- KHÔNG BAO GIỜ nói "xin lỗi, tôi không biết"
- KHÔNG BAO GIỜ nói "hệ thống đang bận"
- LÀM HẾT SỨC để giúp đỡ
- Trả lời TIẾNG VIỆT, giọng thân thiện
- Độ dài: 3-6 câu, ngắn gọn dễ hiểu
- Dùng emoji phù hợp: 🔧⚡💧❄️🛠️✅

VÍ DỤ TRẢ LỜI TỐT:
"🔧 Dựa vào mô tả của bạn, tủ lạnh không lạnh có thể do:
1. Block máy nén hỏng (phổ biến nhất)
2. Gas bị rò rỉ
3. Cảm biến nhiệt độ lỗi

Bạn thử kiểm tra: Block có nóng bất thường không? Có nghe tiếng kêu lạ không?

Nếu block nóng quá → gọi thợ ngay (khoảng 300-500k).
Nếu block nguội → có thể thiếu gas (200-400k).

Có vấn đề gì khác không ạ? 😊"
''';

      List<Part> parts = [];

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }

      final userText = message.isEmpty && imageFile != null
          ? "Phân tích hình ảnh này và chẩn đoán lỗi chi tiết, rồi đưa ra cách sửa"
          : message;

      parts.add(TextPart("$systemPrompt\n\nKhách hàng: $userText"));

      final response = await model.generateContent([Content.multi(parts)]);

      String aiResponse = response.text?.trim() ?? "Bạn có thể mô tả chi tiết hơn được không ạ? 🤔";

      return aiResponse;
    } catch (e) {
      print("Lỗi Gemini: $e");

      // FALLBACK RESPONSE - vẫn hữu ích
      if (message.contains('tủ lạnh') || message.contains('tu lanh')) {
        return '''🔧 Tủ lạnh không lạnh thường do:
1. Block máy nén hỏng (phổ biến)
2. Gas rò rỉ
3. Cảm biến lỗi

Giá sửa khoảng 200-500k tùy lỗi.
Bạn có thể mô tả thêm triệu chứng để tôi tư vấn cụ thể hơn không? 😊''';
      }

      if (message.contains('điều hòa') || message.contains('máy lạnh')) {
        return '''❄️ Máy lạnh không mát thường do:
1. Bẩn lọc gió (tự vệ sinh được)
2. Thiếu gas (200-300k)
3. Block hỏng (500k+)

Bạn thử kiểm tra block nóng bất thường không nhé? 🔧''';
      }

      return "Có vẻ mạng đang chập chờn. Bạn có thể mô tả vấn đề chi tiết hơn để tôi tư vấn tốt hơn được không ạ? 😊";
    }
  }

  static Future<List<String>> analyzeAppliance(File imageFile) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

      final prompt = TextPart('''
BẠN LÀ CHUYÊN GIA SỬA CHỮA ĐỒ ĐIỆN TỬ VÀ GIA DỤNG.

Phân tích hình ảnh thiết bị này và đưa ra 3 chẩn đoán NGẮN GỌN nhất về lỗi có thể xảy ra.
Mỗi chẩn đoán DƯỚI 8 CHỮ, cụ thể, dễ hiểu.

BẮT BUỘC TRẢ VỀ ĐÚNG ĐỊNH DẠNG MẢNG JSON, KHÔNG GIẢI THÍCH.

VÍ DỤ OUTPUT TỐT:
["Block máy nén hỏng", "Thiếu gas lạnh", "Cảm biến nhiệt độ lỗi"]

VÍ DỤ OUTPUT XẤU (KHÔNG LÀM):
["Có thể bị hỏng", "Lỗi không xác định", "Cần kiểm tra"]

QUAN TRỌNG: 
- Phải CỤ THỂ (đúng tên linh kiện)
- Phải NGẮN GỌN (dưới 8 chữ)
- Phải TIẾNG VIỆT thông dụng
      ''');

      final imageBytes = await imageFile.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      String text = response.text ?? "[]";
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();

      final List<dynamic> decodedList = jsonDecode(text);
      List<String> suggestions = decodedList.map((e) => e.toString()).toList();

      // Validate suggestions
      if (suggestions.isEmpty || suggestions.every((s) => s.contains('không xác định') || s.contains('Lỗi'))) {
        return [
          "Kiểm tra nguồn điện",
          "Kiểm tra dây cắm",
          "Liên hệ thợ kiểm tra"
        ];
      }

      return suggestions;

    } catch (e) {
      print("Lỗi AI phân tích ảnh: $e");
      return [
        "Kiểm tra nguồn điện",
        "Kiểm tra kết nối",
        "Gọi thợ kiểm tra chi tiết"
      ];
    }
  }
}