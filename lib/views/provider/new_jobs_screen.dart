import 'package:appthuetho/services/chat_service.dart';
import 'package:appthuetho/views/provider/job_progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../order_tracking_screen.dart';
import '../customer/chat_detail_screen_realtime.dart';
import 'package:url_launcher/url_launcher.dart';
class NewJobsScreen extends StatefulWidget {
  const NewJobsScreen({super.key});

  @override
  State<NewJobsScreen> createState() => _NewJobsScreenState();
}

class _NewJobsScreenState extends State<NewJobsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Đơn mới', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00AEEF),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter dialog
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('status', whereIn: ['pending', 'accepted', 'in_progress'])
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final currentUser = FirebaseAuth.instance.currentUser;
          // Lọc đơn:
          // - pending: chỉ hiển thị nếu thợ chưa từ chối (rejectedBy không chứa currentUserId)
          // - accepted/in_progress: chỉ hiển thị nếu là đơn của thợ này
          final myJobs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'];
            final technicianId = data['technicianId'];
            final currentUserId = currentUser?.uid;

            if (status == 'pending') {
              final rejectedBy = List<String>.from(data['rejectedBy'] ?? []);
              return !rejectedBy.contains(currentUserId);
            } else {
              return technicianId == currentUserId;
            }
          }).toList();

          if (myJobs.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myJobs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot doc = myJobs[index];
                Map<String, dynamic> jobData = doc.data() as Map<String, dynamic>;
                String jobId = doc.id;
                return _buildJobCard(jobId, jobData);
              },
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
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có đơn mới',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống sẽ thông báo khi có đơn mới gần bạn',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(String jobId, Map<String, dynamic> jobData) {
    final status = jobData['status'] ?? 'pending';
    final customerId = jobData['customerId'] ?? '';
    final customerName = jobData['customerName'] ?? 'Khách hàng';
    final customerPhone = jobData['customerPhone'] ?? '';

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isMyJob = jobData['technicianId'] == currentUserId;

    String timeAgo = _getTimeAgo(jobData['createdAt']);
    double estimatedPrice = (jobData['estimatedPrice'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMyJob ? Border.all(color: const Color(0xFF00AEEF), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner nếu đã nhận
          if (isMyJob) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getStatusIcon(status), color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Header: Customer Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              jobData['customerAddress'] ?? 'N/A',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isMyJob)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Service Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00AEEF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getServiceIcon(jobData['serviceType']),
                        color: const Color(0xFF00AEEF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobData['serviceType'] ?? 'Dịch vụ',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            jobData['description'] ?? 'Không có mô tả',
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thu nhập dự kiến
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thu nhập dự kiến:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${estimatedPrice.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Đơn chưa nhận: 3 nút (Chi tiết, Từ chối, Nhận đơn)
                if (!isMyJob)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobProgressScreen(jobId: jobId, jobData: jobData),
                              ),
                            );
                          },
                          child: const Text('Chi tiết', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isLoading ? null : () => _rejectJob(jobId),
                          child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AEEF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : () => _acceptJobAndNavigate(jobId, customerId, jobData),
                          child: const Text('Nhận đơn', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                // Đơn đã nhận: các nút Gọi, Chat, Xem tiến trình
                if (isMyJob) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.call, size: 20),
                          label: const Text('Gọi khách', overflow: TextOverflow.ellipsis),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _makePhoneCall(customerPhone),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat, size: 20),
                          label: const Text('Chat', overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AEEF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          onPressed: () => _openChat(customerId, customerName),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.timeline),
                      label: const Text('Xem tiến trình'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AEEF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobProgressScreen(jobId: jobId, jobData: jobData),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String? serviceType) {
    switch (serviceType) {
      case 'Sửa điện':
        return Icons.electrical_services;
      case 'Sửa nước':
        return Icons.plumbing;
      case 'Sửa điều hòa':
      case 'Vệ sinh máy lạnh':
        return Icons.ac_unit;
      case 'Sửa tủ lạnh':
        return Icons.kitchen;
      case 'Sửa máy giặt':
        return Icons.local_laundry_service;
      default:
        return Icons.build;
    }
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Vừa xong';
    DateTime createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else {
      return 'Vừa xong';
    }
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    return '${diff.inDays} ngày';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF00AEEF);
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.pending_actions;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return '✓ Đã nhận đơn';
      case 'in_progress':
        return '⏳ Đang thực hiện';
      case 'completed':
        return '✅ Đã hoàn thành';
      default:
        return 'Đơn mới';
    }
  }

  // Nhận đơn
  Future<void> _acceptJobAndNavigate(String jobId, String customerId, Map<String, dynamic> jobData) async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Vui lòng đăng nhập');
      DocumentSnapshot techDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!techDoc.exists) throw Exception('Không tìm thấy thông tin thợ');
      Map<String, dynamic> techData = techDoc.data() as Map<String, dynamic>;
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 'accepted',
        'technicianId': currentUser.uid,
        'technicianName': techData['name'] ?? 'Thợ',
        'technicianPhone': techData['phone'] ?? '',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      final chatService = ChatService();
      await chatService.createOrGetChatRoom(customerId, currentUser.uid);

      if (mounted) {
        // Chuyển sang màn hình tiến trình sau khi nhận đơn thành công
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobProgressScreen(jobId: jobId, jobData: {...jobData, 'status': 'accepted'}),
          ),
        );
      }
    } catch (e) {
      print('Lỗi nhận đơn: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  // Từ chối đơn
  Future<void> _rejectJob(String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối đơn?'),
        content: const Text('Bạn có chắc chắn muốn từ chối đơn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Chưa đăng nhập');
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'rejectedBy': FieldValue.arrayUnion([currentUser.uid]),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối đơn'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Lỗi từ chối đơn: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Bắt đầu làm
  Future<void> _startJob(String jobId) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Đã bắt đầu làm việc'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Lỗi start job: $e');
    }
  }

  // Hoàn thành
  Future<void> _completeJob(String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành công việc?'),
        content: const Text('Xác nhận bạn đã hoàn thành xong?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chưa xong'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Đã hoàn thành!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Lỗi complete job: $e');
      }
    }
  }

  // Mở chat
  Future<void> _openChat(String customerId, String customerName) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        _showSnackBar('Vui lòng đăng nhập lại');
        return;
      }

      setState(() => _isLoading = true);

      final chatService = ChatService();
      final chatRoomId = await chatService.createOrGetChatRoom(customerId, currentUserId);
      print('✅ ChatRoomId: $chatRoomId');

      if (!mounted) return;

      // Lấy số điện thoại khách (để gọi trong màn hình chat)
      String customerPhone = '';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(customerId)
            .get();
        if (userDoc.exists) {
          customerPhone = userDoc.data()?['phone'] ?? '';
        }
      } catch (e) {
        print('Lỗi lấy số phone: $e');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chatRoomId: chatRoomId,
            otherUserId: customerId,
            otherUserName: customerName,
            otherUserAvatar: 'https://i.pravatar.cc/150?img=1',
            otherUserPhone: customerPhone, // truyền để gọi
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Lỗi mở chat: $e');
      print(stackTrace);
      if (mounted) {
        _showSnackBar('Không thể mở chat: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// Thêm helper hiển thị snackbar
  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // Gọi điện
  // Gọi điện
  Future<void> _makePhoneCall(String phoneNumber) async {
    // 1. Kiểm tra xem có số điện thoại không đã
    if (phoneNumber.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Đơn hàng này chưa có số điện thoại của khách!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 2. Thực hiện gọi
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thiết bị của bạn không hỗ trợ gọi điện (Có thể bạn đang dùng máy ảo).'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
    }
