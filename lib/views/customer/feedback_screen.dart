// lib/views/customer/feedback_screen.dart  ← TẠO FILE MỚI
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF00AEEF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Phản Hồi & Hỗ Trợ',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Gửi phản hồi'),
            Tab(text: 'Phản hồi của tôi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _SendFeedbackTab(onSent: () {
            _tab.animateTo(1);
          }),
          const _MyFeedbackTab(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1: Gửi phản hồi mới
// ══════════════════════════════════════════════════════════════
class _SendFeedbackTab extends StatefulWidget {
  final VoidCallback onSent;
  const _SendFeedbackTab({required this.onSent});

  @override
  State<_SendFeedbackTab> createState() => _SendFeedbackTabState();
}

class _SendFeedbackTabState extends State<_SendFeedbackTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _selectedType = 'Vấn đề về thợ';
  int _rating = 0;
  bool _loading = false;

  final List<String> _types = [
    'Vấn đề về thợ',
    'Vấn đề về đơn hàng',
    'Vấn đề về thanh toán',
    'Ứng dụng bị lỗi',
    'Góp ý cải thiện',
    'Khác',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showSnack('Vui lòng đăng nhập để gửi phản hồi', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      // Lấy tên user
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Khách hàng';

      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': uid,
        'userName': userName,
        'type': _selectedType,
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'rating': _rating,
        'status': 'pending', // pending | processing | resolved
        'reply': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleCtrl.clear();
      _contentCtrl.clear();
      setState(() {
        _rating = 0;
        _selectedType = 'Vấn đề về thợ';
      });

      _showSuccessDialog();
    } catch (e) {
      _showSnack('Gửi thất bại: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gửi thành công!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cảm ơn bạn đã phản hồi. Tổng đài sẽ xem xét và liên hệ lại trong 24 giờ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AEEF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSent();
                },
                child: const Text('Xem phản hồi của tôi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotline card
            _HotlineCard(),
            const SizedBox(height: 20),

            // Section: Loại phản hồi
            _buildSectionTitle('Loại phản hồi', Icons.category_rounded),
            const SizedBox(height: 10),
            _buildTypeSelector(),
            const SizedBox(height: 20),

            // Section: Đánh giá
            _buildSectionTitle('Mức độ hài lòng', Icons.star_rounded),
            const SizedBox(height: 10),
            _buildRatingStars(),
            const SizedBox(height: 20),

            // Section: Tiêu đề
            _buildSectionTitle('Tiêu đề', Icons.title_rounded),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleCtrl,
              maxLength: 100,
              decoration: _inputDeco(
                hint: 'Nhập tiêu đề ngắn gọn...',
                prefix: Icons.edit_outlined,
              ),
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
            ),
            const SizedBox(height: 16),

            // Section: Nội dung
            _buildSectionTitle('Nội dung chi tiết', Icons.description_rounded),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contentCtrl,
              maxLines: 6,
              maxLength: 1000,
              decoration: _inputDeco(
                hint:
                'Mô tả chi tiết vấn đề bạn gặp phải để tổng đài có thể hỗ trợ tốt hơn...',
                prefix: Icons.chat_bubble_outline,
              ),
              validator: (v) => v == null || v.trim().length < 10
                  ? 'Nội dung phải có ít nhất 10 ký tự'
                  : null,
            ),
            const SizedBox(height: 24),

            // Nút gửi
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AEEF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _loading ? 'Đang gửi...' : 'Gửi phản hồi đến tổng đài',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF00AEEF)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _types.map((t) {
        final selected = _selectedType == t;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF00AEEF)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? const Color(0xFF00AEEF) : Colors.grey[300]!,
              ),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: const Color(0xFF00AEEF).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
                  : [],
            ),
            child: Text(
              t,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingStars() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final active = i < _rating;
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      active ? Icons.star_rounded : Icons.star_outline_rounded,
                      key: ValueKey(active),
                      color: active ? const Color(0xFFFFC107) : Colors.grey[300],
                      size: 36,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _rating == 0
                ? 'Chưa đánh giá'
                : ['Rất tệ', 'Tệ', 'Trung bình', 'Tốt', 'Rất tốt'][_rating - 1],
            style: TextStyle(
              fontSize: 13,
              color: _rating == 0 ? Colors.grey[400] : Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({required String hint, required IconData prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(prefix, color: Colors.grey[400], size: 20),
      filled: true,
      fillColor: Colors.white,
      counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00AEEF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Widget Hotline Card
// ══════════════════════════════════════════════════════════════
class _HotlineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00AEEF), Color(0xFF0078D7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AEEF).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.headset_mic_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng đài hỗ trợ 24/7',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Phản hồi sẽ được xử lý trong 24h',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: '1800 1234'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Đã sao chép số hotline'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Text(
                    '1800 1234',
                    style: TextStyle(
                      color: Color(0xFF00AEEF),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Miễn phí',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2: Xem phản hồi đã gửi
// ══════════════════════════════════════════════════════════════
class _MyFeedbackTab extends StatelessWidget {
  const _MyFeedbackTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00AEEF)));
        }
        if (snap.hasError) {
          // Lỗi permission → hướng dẫn
          final err = snap.error.toString();
          if (err.contains('PERMISSION_DENIED') ||
              err.contains('permission')) {
            return _buildPermissionError(context);
          }
          return Center(child: Text('Lỗi: $err'));
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmpty();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _FeedbackCard(data: data);
          },
        );
      },
    );
  }

  Widget _buildEmpty() {
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
            child: const Icon(Icons.inbox_rounded,
                size: 48, color: Color(0xFF00AEEF)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có phản hồi nào',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gửi phản hồi đầu tiên của bạn\nđể nhận được hỗ trợ từ tổng đài',
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Thiếu quyền Firestore',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Thêm rule sau vào Firestore:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'match /feedback/{id} {\n'
                        '  allow read: if request.auth.uid\n'
                        '    == resource.data.userId;\n'
                        '  allow create: if request.auth != null;\n'
                        '}',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF333333)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card từng phản hồi ──────────────────────────────────────
class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FeedbackCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final String status = data['status'] as String? ?? 'pending';
    final String title = data['title'] as String? ?? '';
    final String content = data['content'] as String? ?? '';
    final String type = data['type'] as String? ?? '';
    final String reply = data['reply'] as String? ?? '';
    final int rating = data['rating'] as int? ?? 0;
    final Timestamp? ts = data['createdAt'] as Timestamp?;

    final cfg = _statusConfig(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cfg['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cfg['icon'] as IconData,
                          size: 12, color: cfg['color'] as Color),
                      const SizedBox(width: 4),
                      Text(
                        cfg['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cfg['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey),
                  ),
                ),
                const Spacer(),
                Text(
                  ts != null ? _fmt(ts.toDate()) : '',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),

          // Title & content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              content,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[600], height: 1.45),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Rating
          if (rating > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i < rating
                        ? const Color(0xFFFFC107)
                        : Colors.grey[300],
                    size: 16,
                  );
                }),
              ),
            ),

          // Reply từ tổng đài
          if (reply.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.support_agent_rounded,
                          size: 14, color: Colors.green),
                      SizedBox(width: 5),
                      Text(
                        'Phản hồi từ tổng đài',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reply,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case 'processing':
        return {
          'label': 'Đang xử lý',
          'color': Colors.orange,
          'icon': Icons.hourglass_top_rounded,
        };
      case 'resolved':
        return {
          'label': 'Đã giải quyết',
          'color': Colors.green,
          'icon': Icons.check_circle_rounded,
        };
      default:
        return {
          'label': 'Chờ xử lý',
          'color': Colors.blue,
          'icon': Icons.pending_rounded,
        };
    }
  }

  String _fmt(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}p trước';
    if (d.inHours < 24) return '${d.inHours}h trước';
    return DateFormat('dd/MM/yyyy').format(dt);
  }
}