import 'package:flutter/material.dart';

class ProviderChatScreen extends StatelessWidget {
  const ProviderChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat với khách', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              // Đã bỏ chữ 'const' đi để không bị lỗi với NetworkImage
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF00AEEF),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: const Text(
                  'Khách hàng Nguyễn Thị X',
                  style: TextStyle(fontWeight: FontWeight.bold)
              ),
              subtitle: const Text('Sửa tủ lạnh - Q.1'),
              trailing: const Text(
                  '10:45',
                  style: TextStyle(color: Colors.grey, fontSize: 12)
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mở chat chi tiết...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}