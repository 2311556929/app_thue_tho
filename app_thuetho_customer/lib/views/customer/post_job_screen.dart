import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/auth_controller.dart';
import '../../models/job_model.dart';
import 'searching_technician_screen.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/ai_service_updated.dart';  // ← ĐỔI TỪ ai_service.dart

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
// ------------------------------------

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
  final TextEditingController _phoneController = TextEditingController(); // ✅ Thêm controller cho số điện thoại

  String? _selectedService;
  File? _selectedImage;

  // --- BIẾN CHO AI VÀ BÁO GIÁ ---
  List<SuggestionItem> _suggestedIssues = [];
  bool _isAnalyzing = false;
  bool _isTypingOrAnalyzing = false;
  String? _currentEstimatedPrice;
  // ------------------------------

  bool _isLoadingLocation = false;
  bool _isLocaleReady = false;

  double? _latitude;
  double? _longitude;
  DateTime? _scheduledDateTime;

  // Dữ liệu dịch vụ khớp với HomeScreen
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

    // Tự động lấy số điện thoại của user đã đăng nhập gán vào ô nhập liệu
    final user = context.read<AuthController>().currentUser;
    if (user != null) {
      _phoneController.text = user.phone; // ✅ Tự động lưu SĐT
    }

    // Tạo danh sách dropdown tự động từ dữ liệu
    _services = _appliancesData.map((e) => e.name).toList();
    _services.add('Thợ khác');

    if (widget.selectedService != null && _services.contains(widget.selectedService)) {
      _selectedService = widget.selectedService;
    } else if (widget.selectedService != null) {
      _selectedService = 'Thợ khác';
    }

    _getCurrentLocation();

    // Lắng nghe text để gợi ý giá
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
    _phoneController.dispose(); // ✅ Giải phóng bộ nhớ
    super.dispose();
  }

  // --- LOGIC TÌM KIẾM BỆNH VÀ GIÁ KHI GÕ CHỮ ---
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

  // Lấy vị trí
  // Lấy vị trí và dịch ra địa chỉ chi tiết
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // 1. Kiểm tra quyền định vị
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Vui lòng bật GPS/Định vị trên điện thoại';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Chưa cấp quyền truy cập vị trí';
        }
      }

      // 2. Lấy tọa độ GPS chính xác cao
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // 3. Dịch tọa độ thành địa chỉ nhà (Đường, Phường, Quận, TP)
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;

          // Gom các thành phần địa chỉ lại, loại bỏ những phần bị trống
          List<String> addressParts = [];
          if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!); // Số nhà, Tên đường
          if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!); // Phường / Xã
          if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) addressParts.add(place.subAdministrativeArea!); // Quận / Huyện
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!); // Tỉnh / Thành phố

          // Gán chuỗi địa chỉ chi tiết vào ô nhập liệu
          _addressController.text = addressParts.join(', ');
        } else {
          // Dự phòng nếu không dịch được
          _addressController.text = 'Vị trí hiện tại (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        }
      });
    } catch (e) {
      print('Lỗi định vị: $e');
      setState(() {
        // Dự phòng về trung tâm TP.HCM nếu không lấy được vị trí
        _latitude = 10.7769;
        _longitude = 106.7009;
        _addressController.text = ''; // Để trống để khách tự nhập
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể lấy địa chỉ tự động, vui lòng nhập tay!'))
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // Chọn ảnh
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

  // Phân tích ảnh bằng AI và móc nối với Giá
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    setState(() => _isAnalyzing = true);

    try {
      List<String> aiTextSuggestions = await AiService.analyzeAppliance(_selectedImage!);

      List<SuggestionItem> processedItems = [];
      for (String sugg in aiTextSuggestions) {
        String matchPrice = 'Thương lượng với thợ';

        // Khớp bệnh AI trả về với bảng giá
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
    } catch (e) {
      print('Lỗi phân tích AI: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phân tích ảnh, vui lòng mô tả bằng chữ')),
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // Chọn lịch hẹn
  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final initialDate = _scheduledDateTime ?? now.add(const Duration(days: 1));
    final pickedDate = await showDatePicker(context: context, initialDate: initialDate, firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_scheduledDateTime ?? pickedDate));
    if (pickedTime == null) return;

    setState(() {
      _scheduledDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    });
  }

  // Đăng đơn
  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn dịch vụ'))); return;
    }
    if (widget.isScheduling && _scheduledDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày giờ hẹn'))); return;
    }

    final user = context.read<AuthController>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập'))); return;
    }

    final job = Job(
      id: const Uuid().v4(),
      customerId: user.id,
      customerName: user.name,
      customerPhone: _phoneController.text, // ✅ Lấy SĐT từ ô nhập (cho phép user sửa SĐT nếu muốn)
      customerAddress: _addressController.text,
      serviceType: _selectedService!,
      description: _descriptionController.text,
      imagePath: _selectedImage?.path,
      latitude: _latitude ?? 10.7769,
      longitude: _longitude ?? 106.7009,
      status: 'pending',
      createdAt: DateTime.now(),
      scheduledTime: _scheduledDateTime,
    );

    Navigator.push(context, MaterialPageRoute(builder: (_) => SearchingTechnicianScreen(job: job)));
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

              // --- KHU VỰC HIỂN THỊ GỢI Ý & GIÁ TỪ AI ---
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
                            // Tự động điền text và lưu giá
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

              // Khung hiển thị giá dự kiến
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
              // ------------------------------------------

              const SizedBox(height: 24),

              // ✅ KHU VỰC SỐ ĐIỆN THOẠI MỚI THÊM
              const Text('Số điện thoại liên hệ *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone, // Mở bàn phím số
                decoration: InputDecoration(
                  hintText: 'Nhập số điện thoại',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập số điện thoại' : null,
              ),

              const SizedBox(height: 24),

              // KHU VỰC ĐỊA CHỈ GIỮ NGUYÊN
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
                  onPressed: _submitJob,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AEEF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(widget.isScheduling ? 'Xác nhận đặt lịch' : 'Tìm thợ ngay', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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