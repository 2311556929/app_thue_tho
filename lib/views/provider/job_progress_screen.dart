import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/chat_service.dart';
import '../customer/chat_detail_screen_realtime.dart';

class JobProgressScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const JobProgressScreen({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  @override
  State<JobProgressScreen> createState() => _JobProgressScreenState();
}

class _JobProgressScreenState extends State<JobProgressScreen> {
  late String currentStatus;
  bool _isUpdating = false;
  final List<String> _steps = [
    'Đã nhận đơn',
    'Đang trên đường tới',
    'Đã tới nơi',
    'Đang kiểm tra',
    'Bắt đầu làm việc',
    'Hoàn thành',
  ];

  // Map trạng thái từ Firestore sang chỉ số step
  int _getStepIndex(String status) {
    switch (status) {
      case 'accepted':
        return 0;
      case 'on_the_way':
        return 1;
      case 'arrived':
        return 2;
      case 'checking':
        return 3;
      case 'in_progress':
        return 4;
      case 'completed':
        return 5;
      default:
        return 0;
    }
  }

  String _getStatusFromStep(int step) {
    switch (step) {
      case 0:
        return 'accepted';
      case 1:
        return 'on_the_way';
      case 2:
        return 'arrived';
      case 3:
        return 'checking';
      case 4:
        return 'in_progress';
      case 5:
        return 'completed';
      default:
        return 'accepted';
    }
  }

  @override
  void initState() {
    super.initState();
    currentStatus = widget.jobData['status'] ?? 'accepted';
  }

  Future<void> _updateStatus(int newStep) async {
    if (_isUpdating) return;
    final newStatus = _getStatusFromStep(newStep);
    if (newStatus == currentStatus) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'on_the_way') 'onTheWayAt': FieldValue.serverTimestamp(),
        if (newStatus == 'arrived') 'arrivedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'checking') 'checkingAt': FieldValue.serverTimestamp(),
        if (newStatus == 'in_progress') 'startedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        currentStatus = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật: ${_steps[newStep]}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _openChat() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final customerId = widget.jobData['customerId'];
    final customerName = widget.jobData['customerName'] ?? 'Khách hàng';
    if (currentUserId == null || customerId == null) return;

    final chatService = ChatService();
    final chatRoomId = await chatService.createOrGetChatRoom(customerId, currentUserId);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chatRoomId: chatRoomId,
            otherUserId: customerId,
            otherUserName: customerName,
            otherUserAvatar: 'https://i.pravatar.cc/150?img=1',
            otherUserPhone: widget.jobData['customerPhone'] ?? '',
          ),
        ),
      );
    }
  }

  Future<void> _makePhoneCall() async {
    final phone = widget.jobData['customerPhone'];
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có số điện thoại')),
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gọi điện')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _getStepIndex(currentStatus);
    final estimatedPrice = (widget.jobData['estimatedPrice'] ?? 0).toDouble();
    final customerName = widget.jobData['customerName'] ?? 'Khách hàng';
    final customerAddress = widget.jobData['customerAddress'] ?? 'N/A';
    final serviceType = widget.jobData['serviceType'] ?? 'Dịch vụ';
    final description = widget.jobData['description'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chi tiết đơn', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00AEEF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: _openChat,
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _makePhoneCall,
          ),
        ],
      ),
      body: Column(
        children: [
          // Phần thông tin khách hàng
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customerAddress,
                              style: TextStyle(color: Colors.grey[600]),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dịch vụ
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.build, color: const Color(0xFF00AEEF), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      serviceType,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(description, style: TextStyle(color: Colors.grey[700])),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thu nhập dự kiến:'),
                    Text(
                      '${estimatedPrice.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Thanh trượt tiến trình (Slider)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'TIẾN TRÌNH CÔNG VIỆC',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Custom stepper dạng slider ngang
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            // Đường nền
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 20,
                              child: Container(
                                height: 4,
                                color: Colors.grey[300],
                              ),
                            ),
                            // Đường đã qua (màu xanh)
                            Positioned(
                              left: 0,
                              right: constraints.maxWidth * (1 - (currentStep / (_steps.length - 1))),
                              top: 20,
                              child: Container(
                                height: 4,
                                color: const Color(0xFF00AEEF),
                              ),
                            ),
                            // Các điểm step
                            ...List.generate(_steps.length, (index) {
                              final isActive = index <= currentStep;
                              final leftPercent = index / (_steps.length - 1);
                              return Positioned(
                                left: constraints.maxWidth * leftPercent - 20,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => _updateStatus(index),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isActive ? const Color(0xFF00AEEF) : Colors.white,
                                          border: Border.all(
                                            color: isActive ? const Color(0xFF00AEEF) : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          _getStepIcon(index),
                                          color: isActive ? Colors.white : Colors.grey[400],
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          _steps[index],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                            color: isActive ? const Color(0xFF00AEEF) : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nút xác nhận bước tiếp theo (optional)
                  if (currentStep < _steps.length - 1)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00AEEF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isUpdating ? null : () => _updateStatus(currentStep + 1),
                        child: Text(
                          'XÁC NHẬN: ${_steps[currentStep + 1].toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (currentStep == _steps.length - 1)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('HOÀN THÀNH', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cảm ơn bạn đã hoàn thành công việc!')),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0:
        return Icons.check_circle_outline;
      case 1:
        return Icons.directions_car;
      case 2:
        return Icons.location_on;
      case 3:
        return Icons.build;
      case 4:
        return Icons.handyman;
      case 5:
        return Icons.done_all;
      default:
        return Icons.circle;
    }
  }
}