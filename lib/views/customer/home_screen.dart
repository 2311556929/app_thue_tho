// lib/views/customer/home_screen.dart
import 'package:appthuetho/views/customer/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import 'post_job_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _allServices = [
    {'name': 'Sửa điện', 'icon': Icons.electrical_services, 'color': const Color(0xFFF59E0B)},
    {'name': 'Sửa nước', 'icon': Icons.plumbing, 'color': const Color(0xFF3B82F6)},
    {'name': 'Sửa điều hòa', 'icon': Icons.ac_unit, 'color': const Color(0xFF06B6D4)},
    {'name': 'Vệ sinh máy lạnh', 'icon': Icons.cleaning_services, 'color': const Color(0xFF10B981)},
    {'name': 'Sửa tủ lạnh', 'icon': Icons.kitchen, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Sửa máy giặt', 'icon': Icons.local_laundry_service, 'color': const Color(0xFFEC4899)},
    {'name': 'Sửa TV', 'icon': Icons.tv, 'color': const Color(0xFF6366F1)},
    {'name': 'Lò vi sóng', 'icon': Icons.microwave, 'color': const Color(0xFFF59E0B)},
    {'name': 'Bình nóng lạnh', 'icon': Icons.hot_tub, 'color': const Color(0xFFEF4444)},
    {'name': 'Máy lọc nước', 'icon': Icons.water_drop, 'color': const Color(0xFF0EA5E9)},
    {'name': 'Bếp từ', 'icon': Icons.soup_kitchen, 'color': const Color(0xFFDC2626)},
    {'name': 'Máy bơm nước', 'icon': Icons.water, 'color': const Color(0xFF0D9488)},
    {'name': 'Sửa quạt', 'icon': Icons.toys, 'color': const Color(0xFF00AEEF)},
    {'name': 'Máy hút mùi', 'icon': Icons.air, 'color': const Color(0xFF64748B)},
    {'name': 'Cửa cuốn', 'icon': Icons.door_sliding, 'color': const Color(0xFF92400E)},
    {'name': 'Thông tắc cống', 'icon': Icons.hardware, 'color': const Color(0xFF7C3AED)},
    {'name': 'Chống thấm', 'icon': Icons.format_paint, 'color': const Color(0xFF475569)},
    {'name': 'Khoan tường', 'icon': Icons.build, 'color': const Color(0xFF1E293B)},
    {'name': 'Vệ sinh nhà', 'icon': Icons.cleaning_services_outlined, 'color': const Color(0xFF16A34A)},
    {'name': 'Lắp đặt', 'icon': Icons.handyman, 'color': const Color(0xFF2563EB)},
    {'name': 'Thợ khác', 'icon': Icons.more_horiz, 'color': const Color(0xFF94A3B8)},
  ];

  // Promo banners data
  final List<Map<String, dynamic>> _banners = [
    {'title': '🎉 Giảm 20% đơn đầu tiên', 'sub': 'Cho khách hàng mới', 'colors': [const Color(0xFFFF9500), const Color(0xFFFF5F00)]},
    {'title': '⚡ Thợ đến trong 30 phút', 'sub': 'Dịch vụ khẩn cấp 24/7', 'colors': [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)]},
    {'title': '🛡️ Bảo hành 30 ngày', 'sub': 'Tất cả dịch vụ sửa chữa', 'colors': [const Color(0xFF10B981), const Color(0xFF059669)]},
  ];
  int _currentBanner = 0;
  final PageController _bannerCtrl = PageController();

  @override
  void dispose() {
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(user?.name ?? 'Khách hàng'),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildPromoBanners(),
                const SizedBox(height: 24),
                _buildSectionHeader('Dịch vụ phổ biến', null),
                const SizedBox(height: 14),
                _buildServicesGrid(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildSectionHeader('Thợ nổi bật', () {}),
                const SizedBox(height: 14),
                _buildFeaturedTechnicians(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(String name) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF00AEEF),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00AEEF), Color(0xFF0057B8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Xin chào, $name 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bạn cần sửa gì hôm nay?',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _buildNotifButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotifButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => showSearch(
            context: context,
            delegate: ServiceSearchDelegate(services: _allServices)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AEEF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.search_rounded,
                    color: Color(0xFF00AEEF), size: 18),
              ),
              const SizedBox(width: 10),
              Text('Tìm thợ hoặc dịch vụ...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AEEF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Tìm',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanners() {
    return Column(
      children: [
        SizedBox(
          height: 185, // Đã tăng thêm 20px so với lần trước (tổng tăng 45px) để đảm bảo không tràn
          child: PageView.builder(
            controller: _bannerCtrl,
            onPageChanged: (i) => setState(() => _currentBanner = i),
            itemCount: _banners.length,
            itemBuilder: (_, i) {
              final b = _banners[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: b['colors'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (b['colors'] as List<Color>)[0].withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16), // Giữ padding giảm này
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // Thay đổi từ .center sang .start để nội dung không bị dồn xuống đáy
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Thêm một chút padding trên cùng để căn chỉnh
                            const SizedBox(height: 8),
                            Text(
                              b['title'] as String,
                              maxLines: 2, // Cho phép rớt tối đa 2 dòng
                              overflow: TextOverflow.ellipsis, // Dài quá sẽ hiển thị ...
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b['sub'] as String,
                              maxLines: 1, // Chỉ cho phép 1 dòng
                              overflow: TextOverflow.ellipsis, // Dài quá sẽ hiển thị ...
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const PostJobScreen())),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Đặt ngay',
                                  style: TextStyle(
                                    color: (b['colors'] as List<Color>)[0],
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10), // Giữ khoảng cách giữa text và icon
                      const Icon(Icons.celebration_rounded,
                          color: Colors.white54, size: 65), // Giữ size icon giảm này
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
                (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentBanner ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentBanner
                    ? const Color(0xFF00AEEF)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildSectionHeader(String title, VoidCallback? onMore) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          if (onMore != null)
            TextButton(
              onPressed: onMore,
              child: const Text('Xem tất cả',
                  style: TextStyle(
                      color: Color(0xFF00AEEF), fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: 8,
        itemBuilder: (_, i) =>
        i == 7 ? _buildViewAllCard() : _buildServiceCard(_allServices[i]),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> s,
      {bool fromSheet = false}) {
    final color = s['color'] as Color;
    return GestureDetector(
      onTap: () {
        if (fromSheet) Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PostJobScreen(selectedService: s['name'])));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(s['icon'] as IconData, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                s['name'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAllCard() {
    return GestureDetector(
      onTap: _showAllServices,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF00AEEF).withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00AEEF).withOpacity(0.25), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00AEEF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.apps_rounded,
                  color: Color(0xFF00AEEF), size: 26),
            ),
            const SizedBox(height: 8),
            const Text('Xem tất cả',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00AEEF))),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thao tác nhanh',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Đơn khẩn cấp',
                  'Thợ đến trong 30 phút',
                  Icons.bolt_rounded,
                  const Color(0xFFEF4444),
                  const Color(0xFFFEE2E2),
                      () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PostJobScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Đặt lịch',
                  'Chọn thời gian tiện lợi',
                  Icons.calendar_month_rounded,
                  const Color(0xFF00AEEF),
                  const Color(0xFFE0F5FF),
                      () => _showBookingNotice(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String sub, IconData icon,
      Color color, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTechnicians() {
    return SizedBox(
      height: 155,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'provider')
            .limit(10)
            .snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00AEEF)));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
                child: Text('Chưa có thợ', style: TextStyle(color: Colors.grey[400])));
          }
          final list = snap.data!.docs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList()
            ..sort((a, b) =>
                (b['rating'] ?? 0.0).compareTo(a['rating'] ?? 0.0));
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (_, i) => _buildTechCard(list[i]),
          );
        },
      ),
    );
  }

  Widget _buildTechCard(Map<String, dynamic> d) {
    final name = d['name'] as String? ?? 'Thợ';
    final avatar = d['avatar'] as String? ?? '';
    final rating = (d['rating'] ?? 5.0).toDouble();
    final jobs = d['completedJobs'] ?? d['jobCount'] ?? 0;

    return Container(
      width: 115,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[100],
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : const NetworkImage('https://i.pravatar.cc/150?img=11'),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 13),
              const SizedBox(width: 2),
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 3),
          Text('$jobs đơn',
              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  void _showAllServices() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Tất cả dịch vụ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: GridView.builder(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: _allServices.length,
                itemBuilder: (_, i) =>
                    _buildServiceCard(_allServices[i], fromSheet: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingNotice() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Lưu ý khi đặt lịch'),
        content: const Text(
          'Vui lòng đúng hẹn. Khoản cọc cố định sẽ được chuyển cho bên còn lại nếu đối phương vắng mặt.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AEEF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PostJobScreen()));
            },
            child: const Text('Đặt lịch'),
          ),
        ],
      ),
    );
  }
}

// ── Search Delegate ─────────────────────────────────────────
class ServiceSearchDelegate extends SearchDelegate<String?> {
  final List<Map<String, dynamic>> services;
  ServiceSearchDelegate({required this.services});

  @override
  String get searchFieldLabel => 'Nhập dịch vụ cần tìm...';

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final list = query.isEmpty
        ? services
        : services
        .where((s) => s['name']
        .toString()
        .toLowerCase()
        .contains(query.toLowerCase()))
        .toList();

    if (list.isEmpty) {
      return Center(
          child: Text('Không tìm thấy "$query"',
              style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final s = list[i];
        final color = s['color'] as Color;
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(s['icon'] as IconData, color: color, size: 20),
          ),
          title: Text(s['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey),
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    PostJobScreen(selectedService: s['name'] as String)),
          ),
        );
      },
    );
  }
}