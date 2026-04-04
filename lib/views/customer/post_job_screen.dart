import 'dart:io';
import 'package:appthuetho/models/job_model.dart';
import 'package:appthuetho/services/job_service.dart';
import 'package:appthuetho/views/customer/technician_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  String? selectedService = 'Tủ lạnh';
  final TextEditingController descriptionController = TextEditingController();
  File? _selectedImage;           // Ảnh đã chụp
  Position? _currentPosition;     // Vị trí GPS
  final JobService _jobService = JobService();
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng bật GPS')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có quyền truy cập vị trí')));
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => _currentPosition = position);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Đã lấy vị trí: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng yêu cầu sửa chữa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh đã chọn
            if (_selectedImage != null)
              Center(
                child: Image.file(_selectedImage!, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),

            // Upload button
            Row(
              children: [
                _buildUploadButton(Icons.camera_alt, 'Chụp ảnh', _pickImage),
                const SizedBox(width: 16),
                _buildUploadButton(Icons.mic, 'Ghi âm', () {}),
              ],
            ),
            const SizedBox(height: 24),

            // Loại dịch vụ
            const Text('Loại dịch vụ', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedService,
              items: ['Tủ lạnh', 'Máy giặt', 'Điều hòa', 'Cửa sắt', 'Sửa xe máy', 'Thợ điện nước', 'Khác']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => selectedService = value),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // Mô tả
            const Text('Mô tả chi tiết', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Mô tả vấn đề cần sửa...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Địa chỉ + GPS
            ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFF00AEEF)),
              title: const Text('Địa chỉ hiện tại'),
              subtitle: Text(_currentPosition != null
                  ? '${_currentPosition!.latitude}, ${_currentPosition!.longitude}'
                  : '123 Nguyễn Huệ, Q.1, TP.HCM'),
              trailing: IconButton(
                icon: const Icon(Icons.gps_fixed),
                onPressed: _getCurrentLocation,
              ),
            ),

            const SizedBox(height: 32),

            // Nút chính
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chụp ảnh vấn đề')),
                    );
                    return;
                  }
                  if (_currentPosition == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng lấy vị trí GPS')),
                    );
                    return;
                  }

                  final newJob = Job(
                    customerId: 'customer_001',
                    serviceType: selectedService ?? 'Khác',
                    description: descriptionController.text.isEmpty
                        ? 'Không mô tả'
                        : descriptionController.text,
                    imagePath: _selectedImage!.path,
                    latitude: _currentPosition!.latitude,
                    longitude: _currentPosition!.longitude,
                  );

                  final result = await _jobService.createJobAndGetSuggestions(newJob);

                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Đã đăng yêu cầu! Đang gợi ý thợ gần nhất...')),
                    );

                    // Chuyển sang màn hình danh sách thợ
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TechnicianListScreen(
                          suggestedTechnicians: result['suggestedTechnicians'],
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'] ?? 'Lỗi khi gửi yêu cầu')),
                    );
                  }
                },
                child: const Text('Tìm thợ ngay (GPS)', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: const Color(0xFF00AEEF)),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}