import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_model.dart';

class JobService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Emulator
  // Nếu dùng điện thoại thật → thay bằng IP máy tính (ví dụ: http://192.168.1.XXX:3000)

  Future<Map<String, dynamic>> createJobAndGetSuggestions(Job job) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/jobs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(job.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Job created + suggestions received');
        return {
          'success': true,
          'job': data['job'],
          'suggestedTechnicians': data['suggestedTechnicians'] ?? [],
        };
      } else {
        return {'success': false, 'message': 'Lỗi server: ${response.statusCode}'};
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      return {'success': false, 'message': 'Không kết nối được server'};
    }
  }
  // Thợ lấy danh sách job đang chờ
  Future<List<dynamic>> getPendingJobs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/jobs/pending'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Lỗi lấy pending jobs: $e');
      return [];
    }
  }

  // Thợ nhận job
  Future<bool> acceptJob(String jobId, String technicianId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/jobs/$jobId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'technicianId': technicianId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi nhận job: $e');
      return false;
    }
  }
  // Cập nhật trạng thái job
  Future<bool> updateJobStatus(String jobId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/jobs/$jobId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi cập nhật status: $e');
      return false;
    }
  }
}