import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tạo hoặc lấy chat room giữa customer và provider
  Future<String> createOrGetChatRoom(String customerId, String providerId) async {
    // Tạo chatRoomId unique bằng cách sắp xếp 2 IDs
    List<String> ids = [customerId, providerId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final docRef = _firestore.collection('chatRooms').doc(chatRoomId);

    // Sử dụng merge: true để tạo mới nếu chưa tồn tại, hoặc chỉ cập nhật các trường được chỉ định nếu đã tồn tại
    await docRef.set({
      'chatRoomId': chatRoomId,
      'participants': [customerId, providerId],
      'customerId': customerId,
      'providerId': providerId,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatRoomId;
  }
  // Gửi tin nhắn
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String message,
    String? imageUrl,
  }) async {
    try {
      // Thêm message vào subcollection
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Cập nhật lastMessage trong chatRoom
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': message.isEmpty ? '📷 Hình ảnh' : message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // TODO: Gửi push notification cho receiver
    } catch (e) {
      print('Lỗi gửi tin nhắn: $e');
      throw e;
    }
  }

  // Stream messages realtime
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Lấy danh sách chat rooms của user
  Stream<QuerySnapshot> getChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Đánh dấu tin nhắn đã đọc
  Future<void> markMessagesAsRead(String chatRoomId, String currentUserId) async {
    try {
      QuerySnapshot unreadMessages = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Lỗi đánh dấu đã đọc: $e');
    }
  }

  // Đếm số tin nhắn chưa đọc
  Future<int> getUnreadCount(String chatRoomId, String currentUserId) async {
    try {
      QuerySnapshot unreadMessages = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      return unreadMessages.docs.length;
    } catch (e) {
      print('Lỗi đếm tin nhắn: $e');
      return 0;
    }
  }

  // Lấy thông tin người chat
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Lỗi lấy user info: $e');
      return null;
    }
  }

  // Xóa chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      // Xóa tất cả messages
      QuerySnapshot messages = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Xóa chat room
      await _firestore.collection('chatRooms').doc(chatRoomId).delete();
    } catch (e) {
      print('Lỗi xóa chat: $e');
      throw e;
    }
  }
}