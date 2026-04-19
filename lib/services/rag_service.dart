// FILE 2: lib/services/rag_service.dart
// MÔ TẢ: RAG service - tìm context từ CSV trước, Firebase sau
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/csv_knowledge_base.dart';

class RagService {

  /// Lấy RAG context: CSV local → Firebase fallback
  static Future<String> getContext(String userQuery) async {
    // 1. Tìm trong CSV local trước (nhanh, offline được)
    final csvResults = await CsvKnowledgeBase.search(userQuery);

    if (csvResults.isNotEmpty) {
      return _buildContext(csvResults);
    }

    // 2. Fallback: Tìm trên Firestore nếu CSV không có
    try {
      final q = userQuery.toLowerCase();
      final snapshot = await FirebaseFirestore.instance
          .collection('Knowledge_Base')
          .get()
          .timeout(const Duration(seconds: 4));

      final matched = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final item = doc.data();
        final keywords = List<String>.from(item['keywords_list'] ?? []);
        final match = keywords.any((k) => q.contains(k.toLowerCase())) ||
            q.contains((item['category'] ?? '').toString().toLowerCase());
        if (match) matched.add(item);
      }

      if (matched.isNotEmpty) {
        return _buildContext(matched.take(3).toList());
      }
    } catch (e) {
      print('Firestore RAG lỗi: $e');
    }

    return ''; // Không tìm thấy → Gemini tự trả lời
  }

  static String _buildContext(List<Map<String, dynamic>> items) {
    final buffer = StringBuffer();
    buffer.writeln('=== BẢNG GIÁ VÀ THÔNG TIN TỪ DATABASE APPTHUETHO ===');

    for (final item in items) {
      final priceStr = CsvKnowledgeBase.formatPrice(
        item['price_min'] as int? ?? 0,
        item['price_max'] as int? ?? 0,
      );
      final warning = item['warning']?.toString() ?? '';

      buffer.writeln('''
Lỗi: ${item['fault_name']}
Danh mục: ${item['category']}
Triệu chứng: ${item['symptoms']}
Cách xử lý tạm thời: ${item['safe_action']}
Giá sửa tham khảo: $priceStr
${warning.isNotEmpty ? 'CẢNH BÁO: $warning' : ''}
---''');
    }

    buffer.writeln('=== HẾT BẢNG GIÁ ===');
    return buffer.toString();
  }

  /// Seed CSV data lên Firestore (chạy 1 lần để backup lên cloud)
  static Future<void> seedCsvToFirestore() async {
    try {
      final data = await CsvKnowledgeBase.loadData();
      final col = FirebaseFirestore.instance.collection('Knowledge_Base');

      final snap = await col.limit(1).get();
      if (snap.docs.isNotEmpty) {
        print('Firestore đã có data, bỏ qua seed');
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final item in data) {
        final docRef = col.doc(item['id']?.toString() ?? '');
        batch.set(docRef, item);
      }
      await batch.commit();
      print('✅ Đã seed ${data.length} mục lên Firestore!');
    } catch (e) {
      print('Lỗi seed Firestore: $e');
    }
  }

  static String formatPrice(dynamic min, dynamic max) {
    return CsvKnowledgeBase.formatPrice(
      min is int ? min : int.tryParse(min.toString()) ?? 0,
      max is int ? max : int.tryParse(max.toString()) ?? 0,
    );
  }
}

