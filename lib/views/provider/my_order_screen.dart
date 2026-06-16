import 'package:appthuetho/models/order_model.dart';
import 'package:appthuetho/services/order_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final OrderService _orderService = OrderService();
  List<ServiceOrder> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _orders = _orderService.getMyAcceptedOrders();
    });
  }

  Future<void> _startOrder(ServiceOrder order) async {
    setState(() => _isLoading = true);
    await _orderService.startOrder(order.id);
    setState(() => _isLoading = false);
    _loadOrders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.play_circle_fill, color: Colors.white),
              SizedBox(width: 8),
              Text('Đã bắt đầu thực hiện đơn', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _completeOrder(ServiceOrder order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hoàn thành đơn?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Xác nhận bạn đã xử lý xong công việc cho khách hàng này?'),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Chưa xong', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận hoàn thành', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await _orderService.completeOrder(order.id);
      setState(() => _isLoading = false);
      _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('🎉 Đã hoàn thành xuất sắc!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Đơn của tôi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00AEEF)))
          : _orders.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        color: const Color(0xFF00AEEF),
        onRefresh: () async => _loadOrders(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(_orders[index]);
          },
        ),
      ),
    );
  }

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
            child: Icon(Icons.receipt_long_rounded, size: 80, color: Colors.blue.shade200),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có đơn nào',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn làm mới hoặc bật trạng thái trực\ntuyến để nhận các đơn hàng mới nhất.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(ServiceOrder order) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: Trạng thái & Mã đơn ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(order.status), size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        order.status.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // --- INFO: Khách hàng ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(order.customerAvatar),
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_in_talk_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            order.customerPhone,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Nút Gọi Điện xịn xò
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng gọi điện đang phát triển')),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.call_rounded, color: Colors.green.shade600, size: 24),
                  ),
                ),
              ],
            ),
          ),

          // --- DETAILS: Dịch vụ & Địa chỉ ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50, // Nền xám nhẹ tách biệt phần nội dung
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00AEEF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getServiceIcon(order.serviceType), color: const Color(0xFF00AEEF), size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.serviceTitle,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order.description,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_rounded, size: 18, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.address,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- FOOTER: Giá tiền & Nút Hành Động ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Thu nhập dự kiến:',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${order.estimatedPrice.toStringAsFixed(0)}đ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nút chức năng thông minh (Expanded chống tràn)
                Row(
                  children: [
                    if (order.status == OrderStatus.accepted) ...[
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade200, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tính năng hủy đơn đang phát triển')),
                            );
                          },
                          child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AEEF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: () => _startOrder(order),
                          child: const Text('BẮT ĐẦU ĐƠN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                        ),
                      ),
                    ],
                    if (order.status == OrderStatus.inProgress)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
                          label: const Text('HOÀN THÀNH CÔNG VIỆC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                          onPressed: () => _completeOrder(order),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return Icons.schedule_rounded;
      case OrderStatus.inProgress:
        return Icons.directions_run_rounded;
      case OrderStatus.completed:
        return Icons.task_alt_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return const Color(0xFF00AEEF);
      case OrderStatus.inProgress:
        return Colors.orange.shade600;
      case OrderStatus.completed:
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}