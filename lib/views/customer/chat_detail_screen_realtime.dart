// lib/views/customer/chat_detail_screen_realtime.dart
// ✅ SỬA LỖI CHAT: Dùng Align() để tin nhắn mình → PHẢI, người kia → TRÁI
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/chat_service.dart';
import '../../services/notification_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String? otherUserPhone;
  final String? jobId;

  const ChatDetailScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    this.otherUserPhone,
    this.jobId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _chatSvc = ChatService();
  final _picker = ImagePicker();

  // ✅ KEY FIX: lấy UID ngay lúc khởi tạo, không nullable sau đó
  final String _myUid =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _sending = false;
  bool _uploading = false;
  bool _isOtherOnline = false;
  String _otherLastSeen = '';

  @override
  void initState() {
    super.initState();
    // Đánh dấu đã đọc
    if (_myUid.isNotEmpty) {
      _chatSvc.markMessagesAsRead(widget.chatRoomId, _myUid);
    }
    _setMyOnline(true);
    _listenOtherStatus();
  }

  @override
  void dispose() {
    _setMyOnline(false);
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _setMyOnline(bool v) async {
    if (_myUid.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(_myUid).set(
      {
        'isOnline': v,
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  void _listenOtherStatus() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final data = doc.data() ?? {};
      final online = data['isOnline'] as bool? ?? false;
      final lastSeen = data['lastSeen'] as Timestamp?;
      setState(() {
        _isOtherOnline = online;
        if (!online && lastSeen != null) {
          _otherLastSeen = _timeAgo(lastSeen.toDate());
        }
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _myUid.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _chatSvc.sendMessage(
        chatRoomId: widget.chatRoomId,
        senderId: _myUid,
        receiverId: widget.otherUserId,
        message: text,
      );
      _msgCtrl.clear();
      _scrollToBottom();
      // Thông báo cho người kia
      NotificationService.saveAndShow(
        userId: widget.otherUserId,
        title: '💬 Tin nhắn mới',
        body: text.length > 50 ? '${text.substring(0, 50)}...' : text,
        type: 'chat',
        jobId: widget.jobId ?? '',
      );
    } catch (e) {
      _snack('Không thể gửi: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage(ImageSource src) async {
    final f = await _picker.pickImage(
        source: src, imageQuality: 72, maxWidth: 1080);
    if (f == null || _myUid.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final ref = FirebaseStorage.instance
          .ref('chat_images/${widget.chatRoomId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(f.path));
      final url = await ref.getDownloadURL();
      await _chatSvc.sendMessage(
        chatRoomId: widget.chatRoomId,
        senderId: _myUid,
        receiverId: widget.otherUserId,
        message: '',
        imageUrl: url,
      );
      _scrollToBottom();
      NotificationService.saveAndShow(
        userId: widget.otherUserId,
        title: '📷 Đã gửi một ảnh',
        body: widget.otherUserName,
        type: 'chat',
        jobId: widget.jobId ?? '',
      );
    } catch (e) {
      _snack('Tải ảnh lỗi: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _call() async {
    final phone = widget.otherUserPhone;
    if (phone == null || phone.isEmpty) {
      _snack('Không có số điện thoại');
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showImageFull(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(widget.otherUserName),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: _appBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatSvc.getMessages(widget.chatRoomId),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00AEEF)));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return _emptyState();

                // Auto scroll khi có tin mới
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data =
                    docs[i].data() as Map<String, dynamic>;

                    // ✅ FIX CHÍNH: so sánh senderId với _myUid
                    final bool isMe = data['senderId'] == _myUid;

                    // Hiện ngày nếu khác ngày với tin trước
                    final ts = data['timestamp'] as Timestamp?;
                    Widget? dateDivider;
                    if (i == 0 && ts != null) {
                      dateDivider = _dateDivider(ts.toDate());
                    } else if (i > 0 && ts != null) {
                      final prevTs = (docs[i - 1].data()
                      as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      if (prevTs != null &&
                          !_isSameDay(ts.toDate(), prevTs.toDate())) {
                        dateDivider = _dateDivider(ts.toDate());
                      }
                    }

                    return Column(
                      children: [
                        if (dateDivider != null) dateDivider,
                        _bubble(data, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Upload indicator
          if (_uploading)
            Container(
              color: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF00AEEF)),
                ),
                const SizedBox(width: 10),
                Text('Đang gửi ảnh...',
                    style:
                    TextStyle(color: Colors.grey[600], fontSize: 13)),
              ]),
            ),

          _inputBar(),
        ],
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────
  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: const Color(0xFF00AEEF),
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar + online dot
          Stack(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: Colors.white24,
                backgroundImage: widget.otherUserAvatar.isNotEmpty
                    ? NetworkImage(widget.otherUserAvatar)
                    : null,
                child: widget.otherUserAvatar.isEmpty
                    ? Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                )
                    : null,
              ),
              if (_isOtherOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF00AEEF), width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isOtherOnline
                      ? 'Đang hoạt động'
                      : (_otherLastSeen.isNotEmpty
                      ? 'Hoạt động $_otherLastSeen'
                      : 'Không hoạt động'),
                  style: TextStyle(
                    fontSize: 11,
                    color: _isOtherOnline
                        ? Colors.greenAccent
                        : Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (widget.otherUserPhone?.isNotEmpty == true)
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: _call,
          ),
      ],
    );
  }

  // ── Tin nhắn rỗng ────────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00AEEF).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: Color(0xFF00AEEF)),
          ),
          const SizedBox(height: 14),
          Text('Bắt đầu trò chuyện!',
              style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }

  // ── Date divider ─────────────────────────────────────────
  Widget _dateDivider(DateTime dt) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(dt, now)) {
      label = 'Hôm nay';
    } else if (_isSameDay(dt, now.subtract(const Duration(days: 1)))) {
      label = 'Hôm qua';
    } else {
      label =
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  // ── BUBBLE — ĐÃ FIX 2 CHIỀU ─────────────────────────────
  Widget _bubble(Map<String, dynamic> data, bool isMe) {
    final message = data['message'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final ts = data['timestamp'] as Timestamp?;
    final isRead = data['isRead'] as bool? ?? false;
    final time = ts != null
        ? '${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    // ✅ DÙNG Align() — cách đúng để căn bubble sang 2 phía
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,       // Row chỉ co theo nội dung
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar người kia (hiện bên trái)
          if (!isMe) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFF00AEEF).withOpacity(0.15),
              backgroundImage: widget.otherUserAvatar.isNotEmpty
                  ? NetworkImage(widget.otherUserAvatar)
                  : null,
              child: widget.otherUserAvatar.isEmpty
                  ? Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF00AEEF),
                    fontWeight: FontWeight.bold),
              )
                  : null,
            ),
            const SizedBox(width: 6),
          ],

          // Bubble chứa nội dung
          GestureDetector(
            onLongPress: message.isNotEmpty
                ? () {
              Clipboard.setData(ClipboardData(text: message));
              _snack('Đã sao chép tin nhắn');
            }
                : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: imageUrl != null
                    ? const EdgeInsets.all(3)
                    : const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  // Mình → xanh, người kia → trắng
                  color: isMe ? const Color(0xFF00AEEF) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ảnh
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showImageFull(imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            imageUrl,
                            width: 220,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                              width: 220,
                              height: 150,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                            errorBuilder: (_, __, ___) => Container(
                              width: 220,
                              height: 120,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                      ),

                    // Text
                    if (message.isNotEmpty)
                      Text(
                        message,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),

                    // Giờ + tick
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Colors.white70
                                : Colors.grey[400],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 3),
                          Icon(
                            isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 13,
                            color: isRead
                                ? Colors.lightBlueAccent
                                : Colors.white60,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────
  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Ảnh gallery
            _InputBtn(
              icon: Icons.photo_outlined,
              color: const Color(0xFF00AEEF),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            // Camera
            _InputBtn(
              icon: Icons.camera_alt_outlined,
              color: Colors.green,
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(width: 4),

            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(
                        color: Color(0xFFAAAAAA), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send
            GestureDetector(
              onTap: _sending ? null : _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _sending
                      ? Colors.grey[300]
                      : const Color(0xFF00AEEF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: _sending
                    ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
                    : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'vừa xong';
    if (d.inMinutes < 60) return '${d.inMinutes}p trước';
    if (d.inHours < 24) return '${d.inHours}h trước';
    return '${d.inDays}d trước';
  }
}

class _InputBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _InputBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      onPressed: onTap,
      splashRadius: 20,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}