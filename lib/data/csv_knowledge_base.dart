import 'package:flutter/services.dart';

class CsvKnowledgeBase {
  static List<Map<String, dynamic>>? _cache; // Cache để không load lại nhiều lần

  /// Load và parse CSV từ assets một lần duy nhất
  static Future<List<Map<String, dynamic>>> loadData() async {
    if (_cache != null) return _cache!; // Dùng cache nếu đã load rồi

    try {
      final raw = await rootBundle.loadString('assets/knowledge_base_thue_tho.csv');
      final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();

      if (lines.length < 2) return [];

      // Parse header
      final headers = _parseCsvLine(lines[0]);

      // Parse từng dòng data
      final result = <Map<String, dynamic>>[];
      for (int i = 1; i < lines.length; i++) {
        final values = _parseCsvLine(lines[i]);
        if (values.length < headers.length) continue;

        final row = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < values.length; j++) {
          row[headers[j]] = values[j];
        }

        // Convert kiểu dữ liệu
        row['price_min'] = int.tryParse(row['price_min']?.toString() ?? '0') ?? 0;
        row['price_max'] = int.tryParse(row['price_max']?.toString() ?? '0') ?? 0;

        // Parse keywords thành List
        final kwString = row['keywords']?.toString() ?? '';
        row['keywords_list'] = kwString.split(',').map((k) => k.trim()).toList();

        result.add(row);
      }

      _cache = result;
      print('✅ Đã load ${result.length} mục từ CSV knowledge base');
      return result;
    } catch (e) {
      print('❌ Lỗi load CSV: $e');
      return [];
    }
  }

  /// Tìm kiếm các mục phù hợp với câu hỏi
  static Future<List<Map<String, dynamic>>> search(String query) async {
    final data = await loadData();
    final q = query.toLowerCase();

    final scored = <MapEntry<int, Map<String, dynamic>>>[];

    for (final item in data) {
      int score = 0;
      final keywords = List<String>.from(item['keywords_list'] ?? []);

      for (final k in keywords) {
        if (q.contains(k.toLowerCase())) score += 2;
      }
      if (q.contains((item['category'] ?? '').toString().toLowerCase())) score += 1;
      if (q.contains((item['fault_name'] ?? '').toString().toLowerCase())) score += 3;

      if (score > 0) scored.add(MapEntry(score, item));
    }

    // Sắp xếp theo điểm và lấy top 3
    scored.sort((a, b) => b.key.compareTo(a.key));
    return scored.take(3).map((e) => e.value).toList();
  }

  /// Parse một dòng CSV đúng chuẩn (xử lý cả field có dấu phẩy trong dấu ngoặc kép)
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  /// Format giá tiền đẹp
  static String formatPrice(int min, int max) {
    String fmt(int n) {
      if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} triệu';
      return '${(n / 1000).round()}k';
    }
    return '${fmt(min)} – ${fmt(max)}';
  }

  /// Xóa cache (dùng khi cần reload CSV)
  static void clearCache() => _cache = null;
}

