import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import 'chat_detail_screen_realtime.dart';

class ChatScreenRealtime extends StatefulWidget {
  const ChatScreenRealtime({super.key});

  @override
  State<ChatScreenRealtime> createState() => _ChatScreenRealtimeState();
}

class _ChatScreenRealtimeState extends State<ChatScreenRealtime> {
  final ChatService _chatService = ChatService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Chat'),
          backgroundColor: const Color(0xFF00AEEF),
        ),
        body: const Center(
          child: Text('Vui lòng đăng nhập'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00AEEF),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatRooms(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final chatRooms = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoomData = chatRooms[index].data() as Map<String, dynamic>;
              return _buildChatRoomCard(chatRoomData);
            },
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
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Các cuộc trò chuyện sẽ hiển thị ở đây',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomCard(Map<String, dynamic> chatRoomData) {
    final chatRoomId = chatRoomData['chatRoomId'] as String;
    final participants = List<String>.from(chatRoomData['participants'] ?? []);
    final lastMessage = chatRoomData['lastMessage'] ?? '';
    final lastMessageTime = chatRoomData['lastMessageTime'] as Timestamp?;

    // Tìm ID của người kia (không phải mình)
    final otherUserId = participants.firstWhere(
          (id) => id != _currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return const SizedBox();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _chatService.getUserInfo(otherUserId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
        }

        final otherUser = userSnapshot.data!;
        final otherUserName = otherUser['name'] ?? 'Người dùng';
        final otherUserAvatar = otherUser['avatar'] ?? 'https://i.pravatar.cc/150';
        final otherUserRole = otherUser['role'] ?? '';

        String roleLabel = '';
        if (otherUserRole == 'provider') {
          roleLabel = 'Thợ';
        } else if (otherUserRole == 'customer') {
          roleLabel = 'Khách hàng';
        }

        String timeAgo = '';
        if (lastMessageTime != null) {
          final dateTime = lastMessageTime.toDate();
          final diff = DateTime.now().difference(dateTime);
          if (diff.inMinutes < 1) {
            timeAgo = 'Vừa xong';
          } else if (diff.inMinutes < 60) {
            timeAgo = '${diff.inMinutes} phút';
          } else if (diff.inHours < 24) {
            timeAgo = '${diff.inHours} giờ';
          } else {
            timeAgo = '${diff.inDays} ngày';
          }
        }

        return FutureBuilder<int>(
          future: _chatService.getUnreadCount(chatRoomId, _currentUserId!),
          builder: (context, unreadSnapshot) {
            final unreadCount = unreadSnapshot.data ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(otherUserAvatar),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherUserName,
                        style: TextStyle(
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (roleLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: otherUserRole == 'provider' ? Colors.orange[100] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: otherUserRole == 'provider' ? Colors.orange[900] : Colors.blue[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    lastMessage.isEmpty ? 'Chưa có tin nhắn' : lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: unreadCount > 0 ? const Color(0xFF00AEEF) : Colors.grey[600],
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        chatRoomId: chatRoomId,
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                        otherUserAvatar: otherUserAvatar,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}