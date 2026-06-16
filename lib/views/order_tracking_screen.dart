import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appthuetho/services/chat_service.dart';
import 'package:appthuetho/views/customer/chat_detail_screen_realtime.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String jobId;
  final bool isProvider; // true nếu là thợ, false nếu là khách

  const OrderTrackingScreen({
    super.key,
    required this.jobId,
    this.isProvider = false,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isProvider ? 'Theo dõi công việc' : 'Theo dõi đơn hàng'),
        backgroundColor: const Color(0xFF00AEEF),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy đơn hàng'));
          }

          Map<String, dynamic> jobData = snapshot.data!.data() as Map<String, dynamic>;
          String status = jobData['status'] ?? 'pending';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Timeline status
                _buildStatusTimeline(status),

                const SizedBox(height: 24),

                // Job Details
                _buildJobDetails(jobData),

                const SizedBox(height: 24),

                // Thông tin thợ/khách hàng
                if (status != 'pending') _buildContactInfo(jobData, widget.isProvider),

                const SizedBox(height: 24),

                // Action buttons
                if (!widget.isProvider) _buildCustomerActions(status, jobData), // Truyền thêm jobData vào đây
                if (widget.isProvider) _buildProviderActions(status),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // Hàm xử lý khi bấm nút Nhắn tin
  Future<void> _handleChat(Map<String, dynamic> jobData) async {
    try {
      String customerId = (jobData['customerId'] ?? '').toString();
      String providerId = (jobData['technicianId'] ?? jobData['providerId'] ?? '').toString();

      if (customerId.isEmpty || providerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có đủ thông tin Khách và Thợ để chat!')),
        );
        return;
      }

      String otherUserId = widget.isProvider ? customerId : providerId;
      String otherUserName = widget.isProvider
          ? (jobData['customerName'] ?? 'Khách hàng').toString()
          : (jobData['technicianName'] ?? jobData['providerName'] ?? 'Thợ').toString();

      String otherUserPhone = widget.isProvider
          ? (jobData['customerPhone'] ?? '').toString()
          : (jobData['technicianPhone'] ?? jobData['providerPhone'] ?? '').toString();

      String otherUserAvatar = widget.isProvider
          ? (jobData['customerAvatar'] ?? '').toString()
          : (jobData['technicianAvatar'] ?? jobData['providerAvatar'] ?? '').toString();

      if (otherUserAvatar.isEmpty) {
        otherUserAvatar = widget.isProvider
            ? 'https://i.pravatar.cc/150?img=1'
            : 'https://i.pravatar.cc/150?img=11';
      }

      String chatRoomId = await ChatService().createOrGetChatRoom(customerId, providerId);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatRoomId: chatRoomId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserAvatar: otherUserAvatar,
            otherUserPhone: otherUserPhone,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi hệ thống: $e')));
    }
  }

  // Hàm xử lý gọi điện
  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Người dùng này chưa cập nhật số điện thoại!')),
      );
      return;
    }

    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiết bị của bạn không hỗ trợ gọi điện')),
      );
    }
  }

  Widget _buildStatusTimeline(String currentStatus) {
    List<Map<String, dynamic>> statuses = [
      {'title': 'Đang tìm thợ', 'status': 'pending', 'icon': Icons.search},
      {'title': 'Đã nhận đơn', 'status': 'accepted', 'icon': Icons.check_circle},
      {'title': 'Đang thực hiện', 'status': 'in_progress', 'icon': Icons.build},
      {'title': 'Hoàn thành', 'status': 'completed', 'icon': Icons.done_all},
    ];

    int currentIndex = statuses.indexWhere((s) => s['status'] == currentStatus);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(statuses.length, (index) {
          bool isCompleted = index <= currentIndex;
          bool isCurrent = index == currentIndex;

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF00AEEF) : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statuses[index]['icon'], color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statuses[index]['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCompleted ? Colors.black87 : Colors.grey,
                          ),
                        ),
                        if (isCurrent)
                          const Text('Đang xử lý...', style: TextStyle(fontSize: 12, color: Color(0xFF00AEEF))),
                      ],
                    ),
                  ),
                ],
              ),
              if (index < statuses.length - 1)
                Container(
                  margin: const EdgeInsets.only(left: 25, top: 8, bottom: 8),
                  width: 2,
                  height: 40,
                  color: isCompleted ? const Color(0xFF00AEEF) : Colors.grey[300],
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildJobDetails(Map<String, dynamic> jobData) {
    String paymentStatus = jobData['paymentStatus'] ?? 'unpaid';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chi tiết đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (paymentStatus == 'paid')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Đã thanh toán', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const Divider(height: 24),
          _buildDetailRow('Dịch vụ', jobData['serviceType'] ?? 'N/A'),
          _buildDetailRow('Mô tả', jobData['description'] ?? 'Không có'),
          _buildDetailRow('Địa chỉ', jobData['customerAddress'] ?? 'N/A'),
          _buildDetailRow('Giá dự kiến', '${jobData['estimatedPrice'] ?? 0}đ'),
          _buildDetailRow('Mã đơn', '#${widget.jobId.substring(0, 8).toUpperCase()}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildContactInfo(Map<String, dynamic> jobData, bool isProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(isProvider ? 'https://i.pravatar.cc/150?img=1' : 'https://i.pravatar.cc/150?img=11'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProvider ? (jobData['customerName'] ?? 'Khách hàng') : (jobData['technicianName'] ?? 'Thợ'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isProvider ? (jobData['customerPhone'] ?? '') : (jobData['technicianPhone'] ?? ''),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    String phoneToCall = isProvider ? (jobData['customerPhone'] ?? '') : (jobData['technicianPhone'] ?? jobData['providerPhone'] ?? '');
                    _makePhoneCall(phoneToCall);
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Gọi điện'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleChat(jobData),
                  icon: const Icon(Icons.chat),
                  label: const Text('Nhắn tin'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AEEF), foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // LOGIC HIỂN THỊ NÚT CHO KHÁCH HÀNG (ĐÃ TÍCH HỢP THANH TOÁN)
  // =====================================================================
  Widget _buildCustomerActions(String status, Map<String, dynamic> jobData) {
    String paymentStatus = jobData['paymentStatus'] ?? 'unpaid';

    if (status == 'completed') {
      if (paymentStatus != 'paid') {
        // CHƯA THANH TOÁN -> Hiện nút Thanh toán ngay
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showPaymentBottomSheet(context, jobData),
              icon: const Icon(Icons.payment),
              label: const Text('Thanh toán ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        );
      } else {
        // ĐÃ THANH TOÁN -> Hiện nút Đánh giá thợ
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  Text('Đơn hàng đã được thanh toán', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(),
                  icon: const Icon(Icons.star),
                  label: const Text('Đánh giá thợ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    if (status == 'pending' || status == 'accepted') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton.icon(
          onPressed: () => _showCancelDialog(),
          icon: const Icon(Icons.cancel, color: Colors.red),
          label: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: Colors.red),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  // ===================================================================
  // HÀM HIỂN THỊ BOTTOM SHEET THANH TOÁN
  // ===================================================================
  void _showPaymentBottomSheet(BuildContext context, Map<String, dynamic> jobData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        String selectedMethod = 'cash';
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Thanh toán đơn hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text(
                        '${(jobData['estimatedPrice'] ?? 0).toStringAsFixed(0)}đ',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Chọn phương thức', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  _buildPaymentOption(
                    title: 'Tiền mặt', icon: Icons.money, color: Colors.green,
                    isSelected: selectedMethod == 'cash', onTap: () => setModalState(() => selectedMethod = 'cash'),
                  ),
                  _buildPaymentOption(
                    title: 'Ví MoMo', icon: Icons.account_balance_wallet, color: Colors.pink,
                    isSelected: selectedMethod == 'momo', onTap: () => setModalState(() => selectedMethod = 'momo'),
                  ),
                  _buildPaymentOption(
                    title: 'VNPay', icon: Icons.qr_code_scanner, color: Colors.blue,
                    isSelected: selectedMethod == 'vnpay', onTap: () => setModalState(() => selectedMethod = 'vnpay'),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AEEF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isProcessing ? null : () async {
                        setModalState(() => isProcessing = true);
                        await _processPayment(context, widget.jobId, selectedMethod);
                        setModalState(() => isProcessing = false);
                      },
                      child: isProcessing
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Xác nhận thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOption({required String title, required IconData icon, required Color color, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? const Color(0xFF00AEEF) : Colors.grey.shade300, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF00AEEF).withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? const Color(0xFF00AEEF) : Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, String jobId, String method) async {
    try {
      if (method == 'cash') {
        await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
          'paymentStatus': 'paid',
          'paymentMethod': method,
          'paidAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanh toán thành công!'), backgroundColor: Colors.green));
        }
      } else {
        await Future.delayed(const Duration(seconds: 2)); // Chờ ảo 2 giây để fake call API
        await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
          'paymentStatus': 'paid',
          'paymentMethod': method,
          'paidAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thanh toán qua $method thành công!'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi thanh toán: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // =====================================================================

  Widget _buildProviderActions(String status) {
    if (status == 'accepted') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton.icon(
          onPressed: () async {
            await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
              'status': 'in_progress',
              'startedAt': FieldValue.serverTimestamp(),
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã bắt đầu công việc')));
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Bắt đầu làm việc'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF00AEEF)),
        ),
      );
    }

    if (status == 'in_progress') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton.icon(
          onPressed: () async {
            await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
              'status': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hoàn thành!')));
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('Hoàn thành'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green),
        ),
      );
    }
    return const SizedBox();
  }

  void _showRatingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        int rating = 5;
        TextEditingController reviewController = TextEditingController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 16, left: 24, right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Text('Đánh giá dịch vụ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Vui lòng đánh giá trải nghiệm của bạn với thợ', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setModalState(() => rating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(index < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 48),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(_getRatingText(rating), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.amber)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Để lại nhận xét của bạn (Không bắt buộc)...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF00AEEF), width: 2)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cảm ơn bạn đã gửi đánh giá!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AEEF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Gửi đánh giá', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return 'Rất tệ 😞';
      case 2: return 'Không hài lòng 😕';
      case 3: return 'Bình thường 😐';
      case 4: return 'Hài lòng 🙂';
      case 5: return 'Tuyệt vời! 😍';
      default: return '';
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn có chắc muốn hủy đơn này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Không')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
                'status': 'cancelled',
                'cancelledAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đơn')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
  }
}