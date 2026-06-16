import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
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

  // --- WIDGET TIỆN ÍCH CHO GIAO DIỆN MỚI ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937), // Dark grey
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _buildInputDecoration({required String hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade600, size: 20) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00AEEF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Định nghĩa màu chủ đạo
    const Color primaryColor = Color(0xFF00AEEF);
    const Color backgroundColor = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isScheduling ? 'Đặt lịch hẹn' : 'Đặt dịch vụ mới',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: DỊCH VỤ & THỜI GIAN ---
              _buildSectionHeader(widget.isScheduling ? '1. Dịch vụ & Lịch hẹn' : '1. Chọn loại dịch vụ'),
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bạn cần sửa thiết bị gì? *', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedService,
                      style: const TextStyle(color: Colors.black87, fontSize: 15),
                      decoration: _buildInputDecoration(hintText: 'Chọn một loại dịch vụ'),
                      items: _services.map((service) => DropdownMenuItem(value: service, child: Text(service))).toList(),
                      onChanged: (value) => setState(() => _selectedService = value),
                      validator: (value) => value == null ? 'Vui lòng chọn một loại dịch vụ' : null,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ),

                    if (widget.isScheduling) ...[
                      const SizedBox(height: 16),
                      const Text('Thời gian bạn rảnh? *', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickSchedule,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, color: primaryColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _scheduledDateTime == null
                                      ? 'Chọn ngày và giờ hẹn cụ thể'
                                      : (_isLocaleReady ? DateFormat('EEEE, dd/MM/yyyy - HH:mm', 'vi').format(_scheduledDateTime!) : 'Đang tải lịch...'),
                                  style: TextStyle(color: _scheduledDateTime == null ? Colors.grey.shade400 : Colors.black87, fontSize: 15),
                                ),
                              ),
                              Icon(Icons.access_time_filled, color: Colors.grey.shade400, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- SECTION 2: MÔ TẢ & HÌNH ẢNH ---
              _buildSectionHeader('2. Tình trạng & Hình ảnh'),
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mô tả chi tiết tình trạng *', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                      decoration: _buildInputDecoration(hintText: 'Mô tả vấn đề thiết bị của bạn đang gặp phải, các dấu hiệu lỗi...'),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập mô tả tình trạng chi tiết' : null,
                    ),

                    const SizedBox(height: 16),
                    // Vùng picker hình ảnh được nâng cấp
                    if (_selectedImage == null)
                      GestureDetector(
                        onTap: () {
                          // Hiển thịBottomSheet để chọn nguồn ảnh
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (builder) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Chọn nguồn ảnh thiết bị', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(child: _buildImageSourceButton(Icons.camera_alt, 'Chụp ảnh mới', primaryColor, () {
                                          Navigator.pop(context);
                                          _pickImage(ImageSource.camera);
                                        })),
                                        const SizedBox(width: 16),
                                        Expanded(child: _buildImageSourceButton(Icons.photo_library, 'Chọn từ thư viện', primaryColor, () {
                                          Navigator.pop(context);
                                          _pickImage(ImageSource.gallery);
                                        })),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF), // Rất nhẹ xanh
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.3), style: BorderStyle.solid, width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: primaryColor, size: 40),
                              const SizedBox(height: 12),
                              const Text('Thêm hình ảnh thiết bị lỗi', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('(Giúp thợ đoán bệnh & AI báo giá chính xác)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_selectedImage!, height: 180, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 10, right: 10,
                            child: GestureDetector(
                              onTap: () => setState(() { _selectedImage = null; _suggestedIssues = []; _currentEstimatedPrice = null; }),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- SECTION: AI ANALYSIS ---
              if (_isAnalyzing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: const [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor)),
                      SizedBox(width: 12),
                      Text('Công nghệ AI đang phân tích lỗi & gợi ý giá...', style: TextStyle(color: Color(0xFF0369A1), fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),

              if (!_isAnalyzing && _isTypingOrAnalyzing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _suggestedIssues.isNotEmpty
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text('AI gợi ý vấn đề & mức giá tham khảo:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 8.0,
                        children: _suggestedIssues.map((item) => GestureDetector(
                          onTap: () {
                            _descriptionController.text = item.title;
                            _descriptionController.selection = TextSelection.fromPosition(TextPosition(offset: _descriptionController.text.length));
                            setState(() => _currentEstimatedPrice = item.price);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              '${item.title} (${item.price})',
                              style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  )
                      : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade200)),
                    child: const Text("💡 Tip: Nhập mô tả chi tiết hơn hoặc chụp ảnh lỗi để nhận gợi ý giá từ AI chính xác nhất nhé!", style: TextStyle(color: Color(0xFF0369A1), fontSize: 14, height: 1.4)),
                  ),
                ),

              if (_currentEstimatedPrice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Giá AI tham khảo: $_currentEstimatedPrice', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('(Giá cuối cùng thợ sẽ chốt sau khi kiểm tra trực tiếp)', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, height: 1.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // --- SECTION 3: LIÊN HỆ & ĐỊA CHỈ ---
              _buildSectionHeader('3. Liên hệ & Địa chỉ'),
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Số điện thoại liên hệ *', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 15),
                      decoration: _buildInputDecoration(hintText: 'Ví dụ: 0912xxxxxx', prefixIcon: Icons.phone_enabled_outlined),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập số điện thoại' : null,
                    ),

                    const SizedBox(height: 16),
                    const Text('Địa chỉ thiết bị *', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      style: const TextStyle(fontSize: 15),
                      decoration: _buildInputDecoration(
                        hintText: 'Nhập địa chỉ của bạn hoặc dùng GPS',
                        prefixIcon: Icons.home_work_outlined,
                      ).copyWith(
                        suffixIcon: _isLoadingLocation
                            ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)))
                            : IconButton(icon: const Icon(Icons.my_location, color: primaryColor, size: 20), onPressed: _getCurrentLocation),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập địa chỉ của thiết bị' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- NÚT BẤM CHỐT - ĐƯỢC NÂNG CẤP CHUYÊN NGHIỆP ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // Bo tròn cực đại
                    elevation: 5,
                    shadowColor: primaryColor.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    widget.isScheduling ? 'XÁC NHẬN ĐẶT LỊCH NGAY' : 'TÌM THỢ ĐẾN NGAY',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Widget tiện ích cho nút chọn nguồn ảnh trong BottomSheet
  Widget _buildImageSourceButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}