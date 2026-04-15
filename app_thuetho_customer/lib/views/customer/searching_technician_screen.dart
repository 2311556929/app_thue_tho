import 'package:app_thuetho_customer/models/job_model.dart';
import 'package:app_thuetho_customer/services/job_service.dart';
import 'package:app_thuetho_customer/views/customer/technician_list_screen.dart';
import 'package:flutter/material.dart';


class SearchingTechnicianScreen extends StatefulWidget {
  final Job job;   // Nhận job từ trang Post Job

  const SearchingTechnicianScreen({super.key, required this.job});

  @override
  State<SearchingTechnicianScreen> createState() => _SearchingTechnicianScreenState();
}

class _SearchingTechnicianScreenState extends State<SearchingTechnicianScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchTechnicians();
  }

  Future<void> _searchTechnicians() async {
    final jobService = JobService();
    final result = await jobService.createJobAndGetSuggestions(widget.job);

    if (mounted) {
      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TechnicianListScreen(
              suggestedTechnicians: result['suggestedTechnicians'],
            ),
          ),
        );
      } else {
        Navigator.pop(context); // Quay lại nếu lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi khi tìm thợ, vui lòng thử lại')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            // Animation loading
            const CircularProgressIndicator(
              color: Color(0xFF00AEEF),
              strokeWidth: 6,
            ),
            const SizedBox(height: 40),
            const Text(
              'Đang tìm thợ gần nhất...',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chỉ mất vài giây thôi ạ',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 80),
            // Có thể thêm icon thợ hoặc map nhỏ nếu muốn
            Image.asset(
              'assets/images/searching.gif',
              height: 120,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.search, size: 120, color: Color(0xFF00AEEF)),
            ),
          ],
        ),
      ),
    );
  }
}