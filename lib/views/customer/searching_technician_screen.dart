import 'package:appthuetho/views/customer/technician_list_screen.dart';
import 'package:flutter/material.dart';

class SearchingTechnicianScreen extends StatefulWidget {
  final String jobId; // Nhận ID của đơn hàng vừa tạo
  final List<Map<String, dynamic>> suggestedTechnicians; // Nhận danh sách thợ đã tìm thấy

  const SearchingTechnicianScreen({
    super.key,
    required this.jobId,
    required this.suggestedTechnicians,
  });

  @override
  State<SearchingTechnicianScreen> createState() => _SearchingTechnicianScreenState();
}

class _SearchingTechnicianScreenState extends State<SearchingTechnicianScreen> {
  @override
  void initState() {
    super.initState();
    _simulateSearchAndNavigate();
  }

  Future<void> _simulateSearchAndNavigate() async {
    // Tạo độ trễ giả 2 giây để hiển thị UI "Đang tìm thợ..." cho khách hàng thấy
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Chuyển sang màn hình danh sách thợ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TechnicianListScreen(
            // Truyền jobId sang để lát nữa khách chọn thợ nào thì cập nhật vào đúng đơn đó
            jobId: widget.jobId,
            suggestedTechnicians: widget.suggestedTechnicians,
          ),
        ),
      );
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
              'Đang lọc thợ gần nhất...',
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