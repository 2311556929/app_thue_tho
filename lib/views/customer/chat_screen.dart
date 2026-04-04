import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          // Danh sách chat gần đây (có thể mở rộng sau)
          ListTile(
            leading: const CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1')),
            title: const Text('Nguyễn Văn A - Thợ điện'),
            subtitle: const Text('Tôi đã xem yêu cầu của bạn...'),
            trailing: const Text('10:32', style: TextStyle(color: Colors.grey)),
            onTap: () {
              // Sau này mở chat chi tiết
            },
          ),
          const Divider(),
          const Spacer(),
          const Center(child: Text('Chưa có tin nhắn nào', style: TextStyle(color: Colors.grey))),
          const Spacer(),
        ],
      ),
    );
  }
}