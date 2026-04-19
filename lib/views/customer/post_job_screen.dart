import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thêm import này
import 'dart:math'; // Thêm import này
import '../../controllers/auth_controller.dart';
import '../../models/job_model.dart';
import 'searching_technician_screen.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/ai_service_updated.dart';
import 'package:firebase_storage/firebase_storage.dart';

// --- DATA MODEL CHO AI GỢI Ý GIÁ ---
class ApplianceIssue {
  final String issueName;
  final String price;
  ApplianceIssue(this.issueName, this.price);
}

class Appliance {
  final String name;
  final List<ApplianceIssue> issues;
  Appliance(this.name, this.issues);
}

class SuggestionItem {
  final String title;
  final String price;
  SuggestionItem(this.title, this.price);
}

class PostJobScreen extends StatefulWidget {
  final String? selectedService;
  final bool isScheduling;
  const PostJobScreen({super.key, this.selectedService, this.isScheduling = false});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedService;
  File? _selectedImage;

  List<SuggestionItem> _suggestedIssues = [];
  bool _isAnalyzing = false;
  bool _isTypingOrAnalyzing = false;
  String? _currentEstimatedPrice;

  bool _isLoading = false; // Thêm biến loading này để kiểm soát trạng thái đăng đơn
  bool _isLoadingLocation = false;
  bool _isLocaleReady = false;

  double? _latitude;
  double? _longitude;
  DateTime? _scheduledDateTime;

  final List<Appliance> _appliancesData = [
    Appliance('Sửa điện', [
      ApplianceIssue('Chập điện, nhảy aptomat', '150k - 300k'),
      ApplianceIssue('Sửa/thay ổ cắm, công tắc', '100k - 200k'),
      ApplianceIssue('Mất điện cục bộ', '200k - 400k'),
    ]),
    Appliance('Sửa nước', [
      ApplianceIssue('Rò rỉ ống nước', '150k - 350k'),
      ApplianceIssue('Hư vòi nước, bồn cầu', '100k - 250k'),
      ApplianceIssue('Thông tắc nghẹt', '250k - 500k'),
    ]),
    Appliance('Sửa điều hòa', [
      ApplianceIssue('Máy không lạnh / Yếu lạnh', '250k - 400k'),
      ApplianceIssue('Chảy nước cục lạnh', '200k - 300k'),
      ApplianceIssue('Nạp gas bổ sung', '250k - 500k'),
      ApplianceIssue('Cục nóng kêu to', '350k - 700k'),
    ]),
    Appliance('Vệ sinh máy lạnh', [
      ApplianceIssue('Vệ sinh máy lạnh treo tường', '150k - 200k'),
      ApplianceIssue('Vệ sinh máy lạnh âm trần', '300k - 450k'),
    ]),
    Appliance('Sửa tủ lạnh', [
      ApplianceIssue('Ngăn mát không lạnh', '250k - 450k'),
      ApplianceIssue('Tủ đóng tuyết dày', '200k - 350k'),
      ApplianceIssue('Kêu to, rung lắc mạnh', '150k - 300k'),
      ApplianceIssue('Hết gas / Thủng dàn', '400k - 800k'),
    ]),
    Appliance('Sửa máy giặt', [
      ApplianceIssue('Không cấp nước / Nước tràn', '200k - 350k'),
      ApplianceIssue('Không xả nước / Không vắt', '250k - 450k'),
      ApplianceIssue('Kêu to, đập thùng', '300k - 500k'),
      ApplianceIssue('Mất nguồn, liệt phím', '350k - 600k'),
    ]),
    Appliance('Sửa TV', [
      ApplianceIssue('Mất nguồn, không lên hình', '300k - 500k'),
      ApplianceIssue('Có tiếng không có hình', '400k - 800k'),
      ApplianceIssue('Nhòe màu, sọc màn hình', 'Thợ kiểm tra báo giá'),
    ]),
    Appliance('Lò vi sóng', [
      ApplianceIssue('Không nóng', '250k - 450k'),
      ApplianceIssue('Đĩa không quay', '150k - 250k'),
      ApplianceIssue('Đánh lửa bên trong', '200k - 350k'),
    ]),
  ];

  List<String> _services = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    if (user != null) {
      _phoneController.text = user.phone;
    }
    _services = _appliancesData.map((e) => e.name).toList();
    _services.add('Thợ khác');
    if (widget.selectedService != null && _services.contains(widget.selectedService)) {
      _selectedService = widget.selectedService;
    } else if (widget.selectedService != null) {
      _selectedService = 'Thợ khác';
    }
    _getCurrentLocation();
    _descriptionController.addListener(_onDescriptionChanged);
    initializeDateFormatting('vi', null).then((_) {
      if (mounted) setState(() => _isLocaleReady = true);
    });
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_onDescriptionChanged);
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    String text = _descriptionController.text.toLowerCase();
    if (text.isEmpty) {
      setState(() {
        _suggestedIssues = [];
        _isTypingOrAnalyzing = false;
        _currentEstimatedPrice = null;
      });
      return;
    }
    List<SuggestionItem> matches = [];
    for (var app in _appliancesData) {
      for (var issue in app.issues) {
        if (issue.issueName.toLowerCase().contains(text) || text.contains(issue.issueName.toLowerCase())) {
          matches.add(SuggestionItem("${app.name} - ${issue.issueName}", issue.price));
        }
      }
    }
    setState(() {
      _suggestedIssues = matches;
      _isTypingOrAnalyzing = true;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Vui lòng bật GPS/Định vị trên điện thoại';
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Chưa cấp quyền truy cập vị trí';
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          List<String> addressParts = [];
          if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
          if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
          if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) addressParts.add(place.subAdministrativeArea!);
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
          _addressController.text = addressParts.join(', ');
        }
      });
    } catch (e) {
      setState(() {
        _latitude = 10.7769; _longitude = 106.7009;
      });
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isTypingOrAnalyzing = false;
      });
      await _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    setState(() => _isAnalyzing = true);
    try {
      List<String> aiTextSuggestions = await AiService.analyzeAppliance(_selectedImage!);
      List<SuggestionItem> processedItems = [];
      for (String sugg in aiTextSuggestions) {
        String matchPrice = 'Thương lượng với thợ';
        for (var app in _appliancesData) {
          for (var issue in app.issues) {
            if (sugg.toLowerCase().contains(issue.issueName.toLowerCase())) {
              matchPrice = issue.price;
            }
          }
        }
        processedItems.add(SuggestionItem(sugg, matchPrice));
      }
      setState(() {
        _suggestedIssues = processedItems;
        _isTypingOrAnalyzing = true;
      });
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(context: context, initialDate: now.add(const Duration(days: 1)), firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (pickedTime == null) return;
    setState(() {
      _scheduledDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    });
  }

  // ========================================
  // HÀM _submitJob MỚI ĐÃ DÁN TỪ FILE GỢI Ý
  // ========================================
  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng cung cấp vị trí để tìm thợ gần nhất')),
      );
      return;
    }

    final user = context.read<AuthController>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = 'https://via.placeholder.com/400'; // Placeholder logic
      }

      final jobData = {
        'customerId': user.id,
        'customerName': user.name,
        'customerPhone': _phoneController.text.trim(),
        'customerAddress': _addressController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'serviceType': _selectedService ?? 'Thợ khác',
        'description': _descriptionController.text.trim(),
        'imagePath': imageUrl,
        'estimatedPrice': _parsePrice(_currentEstimatedPrice ?? '0'),
        'status': 'pending', // Luôn khởi tạo là pending
        'technicianId': null,
        'technicianName': null,
        'technicianPhone': null,
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'startedAt': null,
        'completedAt': null,
      };

      if (_scheduledDateTime != null) {
        jobData['scheduledDateTime'] = Timestamp.fromDate(_scheduledDateTime!);
      }

      final docRef = await FirebaseFirestore.instance.collection('jobs').add(jobData); // Lưu vào Firestore

      final suggestedTechnicians = await _findNearbyTechnicians();
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (suggestedTechnicians.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SearchingTechnicianScreen(
              jobId: docRef.id,
              suggestedTechnicians: suggestedTechnicians,
            ),
          ),
        );
      } else {
        // HIỂN THỊ THÔNG BÁO KHI KHÔNG CÓ THỢ NHƯNG ĐƠN VẪN ĐƯỢC TẠO
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('✓ Đã tạo đơn thành công'),
            content: const Text(
              'Hiện chưa có thợ gần bạn.\n\n'
                  'Đơn của bạn đã được lưu và sẽ được thợ nhận khi họ online.\n\n'
                  'Chúng tôi sẽ thông báo cho bạn ngay khi có thợ nhận đơn!',
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AEEF)),
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // HELPER FUNCTIONS TỪ FILE GỢI Ý
  double _parsePrice(String priceString) {
    final match = RegExp(r'(\d+)').firstMatch(priceString);
    if (match != null) {
      final firstNum = int.parse(match.group(0)!);
      if (priceString.toLowerCase().contains('k')) return (firstNum * 1000).toDouble();
      return firstNum.toDouble();
    }
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> _findNearbyTechnicians() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('isOnline', isEqualTo: true)
          .where('serviceTypes', arrayContains: _selectedService)
          .get();

      final List<Map<String, dynamic>> nearbyTechs = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['latitude'] == null || data['longitude'] == null) continue;
        final distance = _calculateDistance(_latitude!, _longitude!, data['latitude'].toDouble(), data['longitude'].toDouble());
        if (distance <= 10.0) {
          nearbyTechs.add({
            'id': doc.id,
            'name': data['name'] ?? 'Thợ',
            'phone': data['phone'] ?? '',
            'avatar': data['avatar'] ?? 'https://i.pravatar.cc/150',
            'rating': data['rating'] ?? 4.5,
            'distance': distance,
          });
        }
      }
      nearbyTechs.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      return nearbyTechs.take(5).toList();
    } catch (e) { return []; }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isScheduling ? 'Đặt lịch hẹn' : 'Đặt dịch vụ'),
        backgroundColor: const Color(0xFF00AEEF),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn dịch vụ *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                hint: const Text('Chọn loại dịch vụ'),
                items: _services.map((service) => DropdownMenuItem(value: service, child: Text(service))).toList(),
                onChanged: (value) => setState(() => _selectedService = value),
                validator: (value) => value == null ? 'Vui lòng chọn dịch vụ' : null,
              ),

              if (widget.isScheduling) ...[
                const SizedBox(height: 24),
                const Text('Thời gian hẹn *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickSchedule,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Color(0xFF00AEEF)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _scheduledDateTime == null
                                ? 'Chọn ngày giờ hẹn'
                                : (_isLocaleReady ? DateFormat('EEEE, dd/MM/yyyy - HH:mm', 'vi').format(_scheduledDateTime!) : 'Đang tải...'),
                            style: TextStyle(color: _scheduledDateTime == null ? Colors.grey : Colors.black, fontSize: 15),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Text('Hình ảnh thiết bị', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt), label: const Text('Chụp ảnh'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library), label: const Text('Thư viện'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),

              if (_selectedImage != null) ...[
                const SizedBox(height: 16),
                Stack(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover)),
                    Positioned(
                      top: 8, right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
                        onPressed: () => setState(() { _selectedImage = null; _suggestedIssues = []; _currentEstimatedPrice = null; }),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              const Text('Mô tả chi tiết *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Mô tả tình trạng, vấn đề cần sửa...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng mô tả chi tiết' : null,
              ),

              if (_isAnalyzing)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('AI đang phân tích & báo giá...', style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),

              if (!_isAnalyzing && _isTypingOrAnalyzing)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _suggestedIssues.isNotEmpty
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Gợi ý bệnh & mức giá:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _suggestedIssues.map((item) => ActionChip(
                          label: Text('${item.title} (${item.price})'),
                          backgroundColor: Colors.green.shade50,
                          side: BorderSide(color: Colors.green.shade200),
                          onPressed: () {
                            _descriptionController.text = item.title;
                            _descriptionController.selection = TextSelection.fromPosition(TextPosition(offset: _descriptionController.text.length));
                            setState(() => _currentEstimatedPrice = item.price);
                          },
                        )).toList(),
                      ),
                    ],
                  )
                      : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Text("💡 Nhập chi tiết hơn hoặc thêm ảnh để AI gợi ý giá chính xác nhé!", style: TextStyle(color: Colors.blue)),
                  ),
                ),

              if (_currentEstimatedPrice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Giá tham khảo: $_currentEstimatedPrice\n(Thợ sẽ kiểm tra thực tế và chốt giá)', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              const Text('Số điện thoại liên hệ *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Nhập số điện thoại',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập số điện thoại' : null,
              ),

              const SizedBox(height: 24),
              const Text('Địa chỉ *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Nhập địa chỉ hoặc dùng vị trí hiện tại',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: _isLoadingLocation
                      ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                      : IconButton(icon: const Icon(Icons.my_location), onPressed: _getCurrentLocation),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập địa chỉ' : null,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitJob,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AEEF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.isScheduling ? 'Xác nhận đặt lịch' : 'Tìm thợ ngay', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}