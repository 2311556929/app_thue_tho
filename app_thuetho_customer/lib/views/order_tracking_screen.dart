import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                if (!widget.isProvider) _buildCustomerActions(status),
                if (widget.isProvider) _buildProviderActions(status),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
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
                  // Icon circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF00AEEF) : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statuses[index]['icon'],
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Status text
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
                          const Text(
                            'Đang xử lý...',
                            style: TextStyle(fontSize: 12, color: Color(0xFF00AEEF)),
                          ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _buildDetailRow('Dịch vụ', jobData['serviceType'] ?? 'N/A'),
          _buildDetailRow('Mô tả', jobData['description'] ?? 'Không có'),
          _buildDetailRow('Địa chỉ', jobData['customerAddress'] ?? 'N/A'),
          _buildDetailRow('Giá dự kiến', '${jobData['estimatedPrice'] ?? 0}đ'),
          _buildDetailRow('Mã đơn', '#${widget.jobId.substring(0, 8)}'),
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
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
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
                backgroundImage: NetworkImage(
                  isProvider
                      ? 'https://i.pravatar.cc/150?img=1' // Avatar khách
                      : 'https://i.pravatar.cc/150?img=11', // Avatar thợ
                ),
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
                    // Call phone
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Gọi điện'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Open chat
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Nhắn tin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AEEF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerActions(String status) {
    if (status == 'completed') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Đánh giá
                  _showRatingDialog();
                },
                icon: const Icon(Icons.star),
                label: const Text('Đánh giá thợ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'pending' || status == 'accepted') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton.icon(
          onPressed: () {
            _showCancelDialog();
          },
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã bắt đầu công việc')),
            );
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Bắt đầu làm việc'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: const Color(0xFF00AEEF),
          ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã hoàn thành!')),
            );
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('Hoàn thành'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.green,
          ),
        ),
      );
    }

    return const SizedBox();
  }

  void _showRatingDialog() {
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đánh giá thợ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn hài lòng với dịch vụ?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => rating = index + 1),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save rating
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
              );
            },
            child: const Text('Gửi đánh giá'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn có chắc muốn hủy đơn này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
                'status': 'cancelled',
                'cancelledAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã hủy đơn')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
  }
}