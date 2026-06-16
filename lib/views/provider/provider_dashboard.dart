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
      duration: const Duration(milliseconds: 2500),
    );
    _loadOnlineStatus();
    _listenToNewOrders();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _loadOnlineStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _isOnline = (doc.data() as Map<String, dynamic>)['isOnline'] ?? false;
          if (_isOnline) {
            _radarController.repeat();
          }
        });
      }
    }
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'isOnline': value});

        setState(() {
          _isOnline = value;
          if (_isOnline) {
            _radarController.repeat();
          } else {
            _radarController.stop();
            _radarController.reset();
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật trạng thái: $e')),
          );
        }
      }
    }
  }

  void _listenToNewOrders() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
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
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00AEEF);
    const Color bgColor = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStatusHeaderCard(primaryColor),
              const SizedBox(height: 40),
              _buildRadarSection(primaryColor),
              const SizedBox(height: 40),
              _buildTodayStatsRow(),
              const SizedBox(height: 24),
              if (_newOrdersCount > 0) _buildNewOrdersAlert(),
            ],
          ),
        ),
      ),
    );
  }

  // --- ĐÃ FIX CĂN LỀ: THÍCH ỨNG TRÊN MỌI MÀN HÌNH ---
  Widget _buildStatusHeaderCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded( // Bọc Expanded để chữ không bao giờ đẩy switch ra ngoài khung
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isOnline ? primaryColor.withOpacity(0.15) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isOnline ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
                    color: _isOnline ? primaryColor : Colors.grey.shade500,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded( // Bọc Expanded để text tự động xuống dòng nếu màn hình quá hẹp
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Trạng thái làm việc', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        _isOnline ? 'Đang hoạt động' : 'Ngoại tuyến',
                        style: TextStyle(
                          color: _isOnline ? const Color(0xFF1F2937) : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isOnline,
            activeColor: primaryColor,
            inactiveTrackColor: Colors.grey.shade300,
            onChanged: _toggleOnlineStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildRadarSection(Color primaryColor) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isOnline) _buildPulseWave(primaryColor, 0.0),
              if (_isOnline) _buildPulseWave(primaryColor, 0.5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOnline ? primaryColor : Colors.grey.shade300,
                  boxShadow: _isOnline ? [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 25, spreadRadius: 5)] : [],
                ),
                child: Icon(_isOnline ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded, color: Colors.white, size: 45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isOnline ? 'Đang dò tìm khách hàng quanh bạn...' : 'Bạn đang tắt nhận đơn',
            key: ValueKey<bool>(_isOnline),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _isOnline ? primaryColor : Colors.grey.shade500,
              fontStyle: _isOnline ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPulseWave(Color color, double delay) {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        final progress = (_radarController.value + delay) % 1.0;
        final size = 100 + (120 * progress);
        final opacity = 1.0 - progress;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(opacity * 0.8), width: 2),
            color: color.withOpacity(opacity * 0.15),
          ),
        );
      },
    );
  }

  Widget _buildTodayStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatMiniCard('Thu nhập h.nay', '0đ', Icons.account_balance_wallet_rounded, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatMiniCard('Đã hoàn thành', '0', Icons.task_alt_rounded, Colors.blue)),
      ],
    );
  }

  Widget _buildStatMiniCard(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade50, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Chống vỡ trục dọc
        children: [
          Icon(icon, color: color.shade500, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // --- ĐÃ FIX CARD CAM: LOẠI BỎ SIZEDBOX HEIGHT ĐỂ BUTTON TỰ ĐỘNG CO DÃN ---
  Widget _buildNewOrdersAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8008), Color(0xFFFFC837)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded( // Giúp nội dung chữ rớt dòng thay vì đẩy ra ngoài
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('TIN NÓNG!', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                      'Có $_newOrdersCount đơn mới quanh bạn',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Không dùng SizedBox height cố định nữa. Ta dùng minimumSize để button thông minh hơn.
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              minimumSize: const Size(double.infinity, 48), // Chỉ quy định độ cao tối thiểu
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 0,
            ),
            onPressed: widget.onViewNewOrders,
            child: Text(
              'XEM NGAY ($_newOrdersCount)',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}