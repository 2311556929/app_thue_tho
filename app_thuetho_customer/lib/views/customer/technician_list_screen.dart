import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen_realtime.dart';

class TechnicianListScreen extends StatelessWidget {
  final List<dynamic> suggestedTechnicians;

  const TechnicianListScreen({super.key, required this.suggestedTechnicians});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thợ gợi ý gần bạn')),
      body: suggestedTechnicians.isEmpty
          ? const Center(child: Text('Không tìm thấy thợ phù hợp'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: suggestedTechnicians.length,
        itemBuilder: (context, index) {
          final tech = suggestedTechnicians[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(tech['avatar'] ?? 'https://i.pravatar.cc/150'),
              ),
              title: Text(tech['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${tech['distance'].toStringAsFixed(1)} km • ⭐ ${tech['rating']} • ${tech['serviceTypes'].join(', ')}',
              ),
              trailing: ElevatedButton(
                onPressed: () async {
                  // ✅ TẠO HOẶC MỞ CHAT ROOM
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  if (currentUserId == null) return;

                  final chatService = ChatService();
                  final chatRoomId = await chatService.createOrGetChatRoom(
                    currentUserId,
                    tech['id'],
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        chatRoomId: chatRoomId,
                        otherUserId: tech['id'],
                        otherUserName: tech['name'],
                        otherUserAvatar: tech['avatar'] ?? 'https://i.pravatar.cc/150',
                      ),
                    ),
                  );
                },
                child: const Text('Chat ngay'),
              ),
            ),
          );
        },
      ),
    );
  }
}
