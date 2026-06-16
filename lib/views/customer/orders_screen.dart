import 'dart:math';
import 'package:appthuetho/models/job_model.dart';
import 'package:appthuetho/views/order_tracking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:appthuetho/views/customer/payment_screen.dart'; // Chỉnh sửa đường dẫn này nếu cấu trúc thư mục của bạn khác

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Đơn hàng của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00AEEF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Vui lòng đăng nhập'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('customerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Lỗi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final jobs = snapshot.data!.docs.map((doc) {
            return Job.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          // Chuyển Map để lấy thêm các field không có trong Job model (ví dụ paymentStatus)
          final rawDocs = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    // Lấy trạng thái thanh toán từ Firestore
                    final rawData = rawDocs[index].data() as Map<String, dynamic>;
                    final paymentStatus = rawData['paymentStatus'] ?? 'unpaid';

                    return _buildOrderCard(context, job, paymentStatus);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa có đơn hàng nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00AEEF) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Job job, String paymentStatus) {
    String statusText;
    Color statusColor;

    switch (job.status) {
      case 'pending':
        statusText = 'Chờ thợ nhận';
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusText = 'Đã có thợ';
        statusColor = Colors.blue;
        break;
      case 'in_progress':
        statusText = 'Đang thực hiện';
        statusColor = Colors.purple;
        break;
      case 'completed':
        statusText = 'Hoàn thành';
        statusColor = Colors.green;
        break;
      default:
        statusText = job.status;
        statusColor = Colors.grey;
    }

    // Kiểm tra xem đơn có cần hiển thị nút thanh toán không (Đã hoàn thành nhưng chưa thanh toán)
    bool canPay = (job.status == 'completed' && paymentStatus != 'paid');

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn #${job.id.substring(0, min(8, job.id.length)).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              job.serviceType,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(child: Text(job.customerAddress, style: TextStyle(color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(job.estimatedPrice ?? 0).toStringAsFixed(0)}đ',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF)),
                    ),
                    // Hiển thị nhãn Đã thanh toán nếu đã trả tiền
                    if (paymentStatus == 'paid')
                      const Text('✓ Đã thanh toán', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(
                            jobId: job.id,
                            isProvider: false,
                          ),
                        ),
                      );
                    },
                    child: const Text('Xem Tiến Độ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
                // NÚT THANH TOÁN (Chỉ hiện khi đơn đã hoàn thành và chưa thanh toán)
                if (canPay) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              jobId: job.id,
                              amount: (job.estimatedPrice ?? 0).toDouble(),
                              serviceType: job.serviceType,
                              // Truyền tên thợ nếu model Job của bạn có (ví dụ: job.technicianName),
                              // nếu chưa có thì tạm để chuỗi mặc định.
                              technicianName: 'Thợ của hệ thống',
                            ),
                          ),
                        );
                      },
                      child: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // // ===================================================================
  // // HÀM HIỂN THỊ BOTTOM SHEET THANH TOÁN (GIỐNG GRAB)
  // // ===================================================================
  // void _showPaymentBottomSheet(BuildContext context, Job job) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (BuildContext context) {
  //       String selectedMethod = 'cash'; // Mặc định là tiền mặt
  //       bool isProcessing = false;
  //
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setModalState) {
  //           return Container(
  //             decoration: const BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //             ),
  //             padding: const EdgeInsets.all(24),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Center(
  //                   child: Container(
  //                     width: 40, height: 4,
  //                     decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 24),
  //                 const Text('Thanh toán đơn hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  //                 const SizedBox(height: 8),
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, color: Colors.grey)),
  //                     Text(
  //                       '${(job.estimatedPrice ?? 0).toStringAsFixed(0)}đ',
  //                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
  //                     ),
  //                   ],
  //                 ),
  //                 const Divider(height: 32),
  //                 const Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //                 const SizedBox(height: 16),
  //
  //                 // DANH SÁCH PHƯƠNG THỨC
  //                 _buildPaymentOption(
  //                   title: 'Tiền mặt',
  //                   icon: Icons.money,
  //                   color: Colors.green,
  //                   isSelected: selectedMethod == 'cash',
  //                   onTap: () => setModalState(() => selectedMethod = 'cash'),
  //                 ),
  //                 _buildPaymentOption(
  //                   title: 'Ví MoMo',
  //                   icon: Icons.account_balance_wallet,
  //                   color: Colors.pink,
  //                   isSelected: selectedMethod == 'momo',
  //                   onTap: () => setModalState(() => selectedMethod = 'momo'),
  //                 ),
  //                 _buildPaymentOption(
  //                   title: 'VNPay',
  //                   icon: Icons.qr_code_scanner,
  //                   color: Colors.blue,
  //                   isSelected: selectedMethod == 'vnpay',
  //                   onTap: () => setModalState(() => selectedMethod = 'vnpay'),
  //                 ),
  //
  //                 const SizedBox(height: 32),
  //
  //                 // NÚT XÁC NHẬN
  //                 SizedBox(
  //                   width: double.infinity,
  //                   height: 50,
  //                   child: ElevatedButton(
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: const Color(0xFF00AEEF),
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //                     ),
  //                     onPressed: isProcessing ? null : () async {
  //                       setModalState(() => isProcessing = true);
  //
  //                       // Gọi hàm xử lý thanh toán thực tế
  //                       await _processPayment(context, job.id, selectedMethod);
  //
  //                       setModalState(() => isProcessing = false);
  //                     },
  //                     child: isProcessing
  //                         ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
  //                         : const Text('Xác nhận thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
  //                   ),
  //                 ),
  //                 SizedBox(height: MediaQuery.of(context).padding.bottom),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
  //
  // Widget _buildPaymentOption({
  //   required String title,
  //   required IconData icon,
  //   required Color color,
  //   required bool isSelected,
  //   required VoidCallback onTap,
  // }) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       margin: const EdgeInsets.only(bottom: 12),
  //       padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         border: Border.all(color: isSelected ? const Color(0xFF00AEEF) : Colors.grey.shade300, width: isSelected ? 2 : 1),
  //         borderRadius: BorderRadius.circular(12),
  //         color: isSelected ? const Color(0xFF00AEEF).withOpacity(0.05) : Colors.white,
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(icon, color: color, size: 28),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
  //           ),
  //           Icon(
  //             isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
  //             color: isSelected ? const Color(0xFF00AEEF) : Colors.grey,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //
  // // ===================================================================
  // // LOGIC XỬ LÝ THANH TOÁN FIREBASE
  // // ===================================================================
  // Future<void> _processPayment(BuildContext context, String jobId, String method) async {
  //   try {
  //     if (method == 'cash') {
  //       // Nếu là tiền mặt -> Cập nhật Firestore ngay lập tức
  //       await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
  //         'paymentStatus': 'paid',
  //         'paymentMethod': method,
  //         'paidAt': FieldValue.serverTimestamp(),
  //       });
  //
  //       if (context.mounted) {
  //         Navigator.pop(context); // Đóng BottomSheet
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Thanh toán thành công!'), backgroundColor: Colors.green),
  //         );
  //       }
  //     } else {
  //       // TODO: Ở ĐÂY BẠN TÍCH HỢP SDK MOMO HOẶC VNPAY
  //       // Tạm thời tạo delay ảo giả lập giao tiếp với ngân hàng
  //       await Future.delayed(const Duration(seconds: 2));
  //
  //       await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
  //         'paymentStatus': 'paid',
  //         'paymentMethod': method,
  //         'paidAt': FieldValue.serverTimestamp(),
  //       });
  //
  //       if (context.mounted) {
  //         Navigator.pop(context); // Đóng BottomSheet
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Thanh toán qua $method thành công!'), backgroundColor: Colors.green),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Lỗi thanh toán: $e'), backgroundColor: Colors.red),
  //       );
  //     }
  //   }
  // }
}