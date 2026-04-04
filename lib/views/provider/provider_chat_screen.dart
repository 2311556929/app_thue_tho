import 'package:flutter/material.dart';

class ProviderChatScreen extends StatelessWidget {
  const ProviderChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat với khách')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5')),
            title: const Text('Khách hàng Nguyễn Thị X'),
            subtitle: const Text('Sửa tủ lạnh - Q.1'),
            trailing: const Text('10:45', style: TextStyle(color: Colors.grey)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mở chat chi tiết với khách...')),
              );
            },
          ),
        ],
      ),
    );
  }
}