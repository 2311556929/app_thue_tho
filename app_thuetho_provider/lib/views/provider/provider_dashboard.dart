import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderDashboard extends StatefulWidget {
  final VoidCallback? onViewNewOrders;

  const ProviderDashboard({super.key, this.onViewNewOrders});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> with SingleTickerProviderStateMixin {
  bool _isOnline = false;
  late AnimationController _radarController;
  int _newOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _loadOnlineStatus();
    _listenToNewOrders();
  }

  Future<void> _loadOnlineStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _isOnline = (doc.data() as Map<String, dynamic>)['isOnline'] ?? false;
          if (_isOnline) {
            _radarController.repeat();
          }
        });
      }
    }
  }

  void _listenToNewOrders() {
    FirebaseFirestore.instance
        .collection('jobs')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _newOrdersCount = snapshot.docs.length;
        });
      }
    });
  }

  Future<void> _toggleOnline(bool value) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isOnline = value;
      if (_isOnline) {
        _radarController.repeat();
      } else {
        _radarController.stop();
      }
    });

    // Update Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({'isOnline': value});
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Map
          _buildFakeMapBackground(),

          // UI Layer
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_isOnline) _buildQuickStats(),
                      ],
                    ),
                  ),
                ),

                // Location Button
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: () {},
                      child: const Icon(Icons.my_location, color: Colors.black87),
                    ),
                  ),
                ),

                // Bottom Panel
                _buildBottomPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFakeMapBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE0E0E0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          GridPaper(
            color: Colors.white.withOpacity(0.5),
            interval: 100,
            divisions: 2,
            subdivisions: 1,
            child: Container(width: double.infinity, height: double.infinity),
          ),
          if (_isOnline)
            RotationTransition(
              turns: _radarController,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00AEEF).withOpacity(0.4),
                      const Color(0xFF00AEEF).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          const Icon(Icons.person_pin_circle, size: 50, color: Color(0xFF00AEEF)),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Xin chào, Thợ A',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber[700], size: 16),
                          const SizedBox(width: 4),
                          const Text(' 4.9', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _isOnline ? 'Đang làm' : 'Nghỉ',
                    style: TextStyle(
                      color: _isOnline ? Colors.green[700] : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: _isOnline,
                  onChanged: _toggleOnline,
                  activeColor: Colors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.monetization_on, 'Thu nhập', '450.000đ', Colors.green),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _statItem(Icons.assignment_turned_in, 'Đơn HT', '3 đơn', const Color(0xFF00AEEF)),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _statItem(Icons.trending_up, 'Tỉ lệ nhận', '95%', Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            margin: const EdgeInsets.only(bottom: 16),
          ),

          if (!_isOnline) ...[
            const Icon(Icons.power_settings_new, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Bạn đang ngoại tuyến', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Bật trực tuyến để bắt đầu nhận đơn quanh khu vực của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AEEF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () => _toggleOnline(true),
                child: const Text(
                  'BẬT TRỰC TUYẾN NGAY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ] else ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00AEEF)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Đang quét đơn quanh đây...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_newOrdersCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Có $_newOrdersCount đơn mới gần bạn đang chờ xác nhận!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: widget.onViewNewOrders,
                  child: Text(
                    'XEM $_newOrdersCount ĐƠN MỚI NGAY',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ]
        ],
      ),
    );
  }
}