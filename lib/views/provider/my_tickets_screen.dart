import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'ticket_detail_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  String _selectedStatus = 'all';

  // Danh sách các bộ lọc
  final List<Map<String, String>> _filters = [
    {'label': 'Tất cả', 'value': 'all'},
    {'label': 'Chờ xử lý', 'value': 'pending'},
    {'label': 'Đang xử lý', 'value': 'in_progress'},
    {'label': 'Đã giải quyết', 'value': 'resolved'},
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00AEEF);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Nền xám sáng hiện đại
      appBar: AppBar(
        title: const Text(
          'Yêu cầu hỗ trợ',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1), // Đường viền mỏng dưới AppBar
        ),
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildCustomTab(filter['label']!, filter['value']!),
                  );
                }).toList(),
              ),
            ),
          ),

          // Tickets list
          Expanded(
            child: _buildTicketsList(),
          ),
        ],
      ),
    );
  }

  // Nút Tab tùy chỉnh cực đẹp
  Widget _buildCustomTab(String label, String status) {
    final isSelected = _selectedStatus == status;
    const Color primaryColor = Color(0xFF00AEEF);

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Vui lòng đăng nhập', style: TextStyle(color: Colors.grey)));
    }

    Query query = FirebaseFirestore.instance
        .collection('supportTickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (_selectedStatus != 'all') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00AEEF)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final ticket = snapshot.data!.docs[index];
            final ticketData = ticket.data() as Map<String, dynamic>;
            return _buildTicketCard(ticket.id, ticketData);
          },
        );
      },
    );
  }

  // Trạng thái trống xịn xò
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent_rounded, size: 80, color: Colors.blue.shade200),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có yêu cầu nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khi bạn gửi yêu cầu hỗ trợ, chúng sẽ\nhiển thị tại đây để bạn tiện theo dõi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  // Card Yêu cầu (Đã được lột xác)
  Widget _buildTicketCard(String ticketId, Map<String, dynamic> ticketData) {
    final status = ticketData['status'] ?? 'pending';
    final category = ticketData['category'] ?? 'Khác';
    final title = ticketData['title'] ?? 'Không có tiêu đề';
    final priority = ticketData['priority'] ?? 'Bình thường';
    final createdAt = ticketData['createdAt'] as Timestamp?;

    String dateString = 'N/A';
    if (createdAt != null) {
      dateString = DateFormat('dd/MM/yyyy • HH:mm').format(createdAt.toDate());
    }

    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticketId: ticketId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card: Badge Trạng thái & Mã ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '#${ticketId.substring(0, 6).toUpperCase()}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tiêu đề
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 28),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // Footer Card: Icon Thời gian, Danh mục, Ưu tiên
                Row(
                  children: [
                    _buildInfoChip(Icons.category_outlined, category),
                    const SizedBox(width: 16),
                    _buildInfoChip(
                      Icons.flag_outlined,
                      priority,
                      iconColor: _getPriorityColor(priority),
                    ),
                    const Spacer(),
                    Text(
                      dateString,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget hiển thị thông tin phụ (Danh mục, Ưu tiên)
  Widget _buildInfoChip(IconData icon, String label, {Color? iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor ?? Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade600;
      case 'in_progress':
        return Colors.blue.shade600;
      case 'resolved':
        return Colors.green.shade600;
      case 'closed':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'in_progress':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã giải quyết';
      case 'closed':
        return 'Đã đóng';
      default:
        return 'Không xác định';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Thấp':
        return Colors.grey.shade600;
      case 'Bình thường':
        return Colors.blue.shade600;
      case 'Cao':
        return Colors.orange.shade600;
      case 'Khẩn cấp':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}