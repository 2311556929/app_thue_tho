import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // Dữ liệu mẫu (Mock data) cho các thông báo
  // Sau này bạn có thể thay thế bằng dữ liệu gọi từ API/Firebase
  final List<Map<String, dynamic>> _notifications = const [
    {
      'id': '1',
      'title': 'Thợ đã nhận đơn! 🛠️',
      'message': 'Anh Nguyễn Văn A (Sửa điện) đã nhận đơn của bạn và đang chuẩn bị di chuyển.',
      'time': 'Vừa xong',
      'type': 'order_accepted',
      'isRead': false, // Chưa đọc sẽ in đậm và có màu nền nhạt
    },
    {
      'id': '2',
      'title': 'Thợ đang đến 🛵',
      'message': 'Thợ đang trên đường đến địa chỉ của bạn. Vui lòng chú ý điện thoại nhé.',
      'time': '10 phút trước',
      'type': 'order_moving',
      'isRead': false,
    },
    {
      'id': '3',
      'title': 'Khuyến mãi đặc biệt 🎉',
      'message': 'Giảm ngay 20% cho dịch vụ Vệ sinh máy lạnh dịp cuối tuần này. Đặt lịch ngay kẻo lỡ!',
      'time': '2 giờ trước',
      'type': 'promo',
      'isRead': true,
    },
    {
      'id': '4',
      'title': 'Hoàn thành dịch vụ ✅',
      'message': 'Dịch vụ Sửa ống nước đã hoàn tất. Bạn vui lòng dành 1 phút để đánh giá thợ nhé!',
      'time': 'Hôm qua',
      'type': 'order_completed',
      'isRead': true,
    },
    {
      'id': '5',
      'title': 'Chào mừng bạn mới!',
      'message': 'Cảm ơn bạn đã tin tưởng sử dụng App Thuê Thợ. Tặng bạn mã NEWBIE giảm 50k cho đơn đầu tiên.',
      'time': '2 ngày trước',
      'type': 'system',
      'isRead': true,
    },
  ];

  // Hàm chọn icon và màu sắc tùy theo loại thông báo
  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'order_accepted':
      case 'order_moving':
        return const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.handyman, color: Colors.white, size: 20),
        );
      case 'order_completed':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
        );
      case 'promo':
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.celebration, color: Colors.white, size: 20),
        );
      default: // system
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.notifications, color: Colors.white, size: 20),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Thêm logic đánh dấu đã đọc tất cả
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu đọc tất cả')),
              );
            },
            child: const Text('Đã đọc', style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
        child: Text(
          'Bạn chưa có thông báo nào',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final bool isRead = notif['isRead'];

          return InkWell(
            onTap: () {
              // TODO: Thêm logic khi bấm vào từng thông báo (chuyển tới đơn hàng, chi tiết k.mãi...)
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                // Nếu chưa đọc thì nền hơi xanh nhẹ, đã đọc thì nền trắng
                color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: isRead
                    ? Border.all(color: Colors.grey.shade200)
                    : Border.all(color: Colors.blue.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _getNotificationIcon(notif['type']),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notif['title'],
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                notif['time'],
                                style: TextStyle(
                                  color: isRead ? Colors.grey[500] : Colors.blue,
                                  fontSize: 12,
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notif['message'],
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}