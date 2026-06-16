// lib/views/customer/notification_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  CollectionReference? get _col => _uid == null
      ? null
      : FirebaseFirestore.instance
      .collection('notifications')
      .doc(_uid)
      .collection('items');

  Stream<QuerySnapshot>? _stream({bool unreadOnly = false}) {
    if (_col == null) return null;
    Query q = _col!.orderBy('createdAt', descending: true).limit(60);
    if (unreadOnly) q = q.where('isRead', isEqualTo: false);
    return q.snapshots();
  }

  Future<void> _markRead(String docId) async {
    await _col?.doc(docId).update({'isRead': true});
  }

  Future<void> _markAllRead() async {
    final snap = await _col?.where('isRead', isEqualTo: false).get();
    if (snap == null || snap.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.done_all, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Đã đánh dấu tất cả là đã đọc'),
          ]),
          backgroundColor: const Color(0xFF00AEEF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteNotif(String docId) async {
    await _col?.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: _buildAppBar(),
      body: _uid == null
          ? const Center(child: Text('Vui lòng đăng nhập'))
          : TabBarView(
        controller: _tab,
        children: [
          _buildList(unreadOnly: false),
          _buildList(unreadOnly: true),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF00AEEF),
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        'Thông báo',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all_rounded),
          tooltip: 'Đánh dấu tất cả đã đọc',
          onPressed: _markAllRead,
        ),
      ],
      bottom: TabBar(
        controller: _tab,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle:
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          const Tab(text: 'Tất cả'),
          Tab(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream(unreadOnly: true),
              builder: (ctx, snap) {
                final count = snap.data?.docs.length ?? 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Chưa đọc'),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList({required bool unreadOnly}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream(unreadOnly: unreadOnly),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00AEEF)));
        }

        // ✅ FIX LỖI PERMISSION: Bắt lỗi và hiển thị hướng dẫn
        if (snap.hasError) {
          final err = snap.error.toString();
          final isPermission = err.contains('PERMISSION_DENIED') ||
              err.contains('permission') ||
              err.contains('Missing or insufficient');
          return _buildErrorState(isPermission, err);
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmpty(unreadOnly);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _NotifCard(
              key: ValueKey(doc.id),
              docId: doc.id,
              data: data,
              onRead: () => _markRead(doc.id),
              onDelete: () => _deleteNotif(doc.id),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(bool isPermission, String err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPermission ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
              size: 72,
              color: isPermission ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              isPermission ? 'Cần cấp quyền Firestore' : 'Có lỗi xảy ra',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (isPermission)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Thêm rule vào Firebase Console\n→ Firestore Database → Rules:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'match /notifications/{uid}/items/{id} {\n'
                            '  allow read, write:\n'
                            '    if request.auth.uid == uid;\n'
                            '}\n\n'
                            'match /feedback/{id} {\n'
                            '  allow read: if request.auth.uid\n'
                            '    == resource.data.userId;\n'
                            '  allow create: if request.auth != null;\n'
                            '}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF7DD3FC),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                err,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool unreadOnly) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF00AEEF).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 48, color: Color(0xFF00AEEF)),
          ),
          const SizedBox(height: 16),
          Text(
            unreadOnly ? 'Bạn đã đọc hết thông báo! 🎉' : 'Chưa có thông báo',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          Text(
            unreadOnly
                ? 'Tuyệt vời! Không có gì chưa đọc.'
                : 'Thông báo đơn hàng và khuyến mãi\nsẽ xuất hiện ở đây',
            style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Card thông báo ──────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onRead;
  final VoidCallback onDelete;

  const _NotifCard({
    super.key,
    required this.docId,
    required this.data,
    required this.onRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRead = data['isRead'] as bool? ?? true;
    final String type = data['type'] as String? ?? 'system';
    final String title = data['title'] as String? ?? '';
    final String message = data['message'] as String? ?? '';
    final Timestamp? ts = data['createdAt'] as Timestamp?;
    final cfg = _cfg(type);

    return Dismissible(
      key: ValueKey(docId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child:
        const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: isRead ? null : onRead,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : cfg.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? const Color(0xFFEEEEEE)
                  : cfg.color.withOpacity(0.3),
              width: isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isRead
                    ? Colors.black.withOpacity(0.04)
                    : cfg.color.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cfg.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cfg.icon, color: cfg.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ts != null ? _ago(ts.toDate()) : '',
                          style: TextStyle(
                            fontSize: 11,
                            color: isRead ? Colors.grey[400] : cfg.color,
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isRead) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: cfg.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Nhấn để đánh dấu đã đọc',
                            style: TextStyle(
                              fontSize: 11,
                              color: cfg.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Cfg _cfg(String type) {
    switch (type) {
      case 'order_accepted':
        return _Cfg(Icons.handyman_rounded, const Color(0xFF00AEEF),
            const Color(0xFFE8F7FF));
      case 'on_the_way':
        return _Cfg(Icons.electric_moped_rounded, const Color(0xFF0078D7),
            const Color(0xFFE5F1FF));
      case 'order_completed':
        return _Cfg(Icons.check_circle_rounded, const Color(0xFF22C55E),
            const Color(0xFFEAFAF0));
      case 'new_job':
        return _Cfg(Icons.work_rounded, const Color(0xFFFF9500),
            const Color(0xFFFFF3E0));
      case 'promo':
        return _Cfg(Icons.local_offer_rounded, const Color(0xFFE91E63),
            const Color(0xFFFCE4EC));
      case 'cancelled':
        return _Cfg(Icons.cancel_rounded, Colors.red, const Color(0xFFFFEBEE));
      default:
        return _Cfg(Icons.notifications_rounded, Colors.grey,
            const Color(0xFFF5F5F5));
    }
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'Vừa xong';
    if (d.inMinutes < 60) return '${d.inMinutes}p';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays == 1) return 'Hôm qua';
    if (d.inDays < 7) return '${d.inDays}d';
    return DateFormat('dd/MM').format(dt);
  }
}

class _Cfg {
  final IconData icon;
  final Color color;
  final Color bg;
  const _Cfg(this.icon, this.color, this.bg);
}