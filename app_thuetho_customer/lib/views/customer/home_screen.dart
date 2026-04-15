import 'package:app_thuetho_customer/views/customer/notification_screen.dart';
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
  // Danh sách 20+ dịch vụ đồng bộ với PostJobScreen
  final List<Map<String, dynamic>> _allServices = [
    {'name': 'Sửa điện', 'icon': Icons.electrical_services, 'color': Colors.orange},
    {'name': 'Sửa nước', 'icon': Icons.plumbing, 'color': Colors.blue},
    {'name': 'Sửa điều hòa', 'icon': Icons.ac_unit, 'color': Colors.cyan},
    {'name': 'Vệ sinh máy lạnh', 'icon': Icons.cleaning_services, 'color': Colors.green},
    {'name': 'Sửa tủ lạnh', 'icon': Icons.kitchen, 'color': Colors.purple},
    {'name': 'Sửa máy giặt', 'icon': Icons.local_laundry_service, 'color': Colors.pink},
    {'name': 'Sửa TV', 'icon': Icons.tv, 'color': Colors.indigo},
    {'name': 'Lò vi sóng', 'icon': Icons.microwave, 'color': Colors.amber},
    {'name': 'Bình nóng lạnh', 'icon': Icons.hot_tub, 'color': Colors.deepOrange},
    {'name': 'Máy lọc nước', 'icon': Icons.water_drop, 'color': Colors.lightBlue},
    {'name': 'Bếp từ', 'icon': Icons.soup_kitchen, 'color': Colors.red},
    {'name': 'Máy bơm nước', 'icon': Icons.water, 'color': Colors.teal},
    {'name': 'Sửa quạt', 'icon': Icons.toys, 'color': Colors.cyanAccent},
    {'name': 'Máy hút mùi', 'icon': Icons.air, 'color': Colors.grey},
    {'name': 'Cửa cuốn', 'icon': Icons.door_sliding, 'color': Colors.brown},
    {'name': 'Thông tắc cống', 'icon': Icons.hardware, 'color': Colors.deepPurple},
    {'name': 'Chống thấm', 'icon': Icons.format_paint, 'color': Colors.blueGrey},
    {'name': 'Khoan tường', 'icon': Icons.build, 'color': Colors.black54},
    {'name': 'Vệ sinh nhà cửa', 'icon': Icons.cleaning_services_outlined, 'color': Colors.lightGreen},
    {'name': 'Lắp đặt', 'icon': Icons.handyman, 'color': Colors.blueAccent},
    {'name': 'Thợ khác', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  void _showBookingNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lưu ý khi đặt lịch'),
        content: const SingleChildScrollView(
          child: Text(
            'Khách lưu ý trước khi đặt lịch, khi đặt lịch thì phải đúng hẹn. '
                'Theo quy định bên appthuetho, khi đặt lịch thì khách và thợ phải cọc 1 khoản tiền cố định, '
                'nếu khách tới ngày hẹn, khi thợ tới mà khách không có nhà thì số tiền cọc đó bồi thường xăng xe cho thợ '
                'và ngược lại, nếu đến hẹn bên thợ không tới thì cọc bên thợ sẽ bồi thường cho khách. '
                'Điều này để bảo đảm cho 2 bên thợ và khách đúng hẹn ạ. '
                'Không ảnh hưởng thời gian của 2 bên khi sử dụng dịch vụ ạ. '
                'Cảm ơn đã sử dụng dịch bên appthuetho ạ.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PostJobScreen(isScheduling: true),
                ),
              );
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  // --- HÀM HIỂN THỊ BOTTOM SHEET "XEM TẤT CẢ" ---
  void _showAllServicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tất cả dịch vụ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: _allServices.length,
                itemBuilder: (context, index) {
                  return _buildServiceCard(_allServices[index], isFromBottomSheet: true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user?.name ?? 'Khách hàng'),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildPromoBanner(),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dịch vụ phổ biến',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        if (index == 7) {
                          return _buildViewAllCard();
                        }
                        return _buildServiceCard(_allServices[index]);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildFeaturedTechnicians(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00AEEF), Color(0xFF0077CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, $userName 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bạn cần sửa gì hôm nay?',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      );
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          // ✅ Thay vì nhảy qua màn hình PostJobScreen ngay, gọi SearchDelegate
          showSearch(
            context: context,
            delegate: ServiceSearchDelegate(services: _allServices),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 12),
              Text('Tìm thợ hoặc dịch vụ...', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎉 Giảm 20% đơn đầu',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cho khách hàng mới',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PostJobScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF9500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Đặt ngay'),
                  ),
                ],
              ),
            ),
            const Icon(Icons.celebration, color: Colors.white, size: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, {bool isFromBottomSheet = false}) {
    return GestureDetector(
      onTap: () {
        if (isFromBottomSheet) {
          Navigator.pop(context);
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostJobScreen(selectedService: service['name']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (service['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(service['icon'], color: service['color'], size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              service['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAllCard() {
    return GestureDetector(
      onTap: _showAllServicesBottomSheet,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.grid_view_rounded, color: Colors.grey, size: 28),
            ),
            const SizedBox(height: 8),
            const Text(
              'Xem tất cả',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
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
          const Text('Thao tác nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Đơn khẩn cấp',
                  Icons.warning_amber_rounded,
                  Colors.red,
                      () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PostJobScreen()));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Đặt lịch',
                  Icons.calendar_today,
                  Colors.blue,
                      () => _showBookingNotice(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTechnicians() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thợ nổi bật', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildTechnicianCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=$index'),
          ),
          const SizedBox(height: 8),
          Text(
            'Thợ ${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text('${4.5 + (index * 0.1)}', style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${(index + 1) * 10} đơn', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// =====================================================================
// ✅ LỚP DELEGATE XỬ LÝ THANH TÌM KIẾM
// =====================================================================
class ServiceSearchDelegate extends SearchDelegate<String?> {
  final List<Map<String, dynamic>> services;

  ServiceSearchDelegate({required this.services});

  // Chữ hiển thị mờ mờ trong thanh tìm kiếm
  @override
  String get searchFieldLabel => 'Nhập dịch vụ cần tìm...';

  // Nút xóa nội dung gõ (Dấu X)
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = ''; // Xóa chữ đã gõ
          },
        )
    ];
  }

  // Nút quay lại (Mũi tên)
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Đóng thanh tìm kiếm
      },
    );
  }

  // Kết quả sau khi bấm phím Enter/Submit
  @override
  Widget buildResults(BuildContext context) {
    return _buildSuggestionsList(context);
  }

  // Gợi ý hiển thị real-time khi đang gõ
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSuggestionsList(context);
  }

  // Hàm dùng chung để lấy ra danh sách khớp với từ khóa
  Widget _buildSuggestionsList(BuildContext context) {
    // Nếu chưa gõ gì thì hiển thị toàn bộ, nếu đã gõ thì lọc ra các tên chứa chữ đó
    final suggestionList = query.isEmpty
        ? services
        : services.where((s) {
      final name = s['name'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    if (suggestionList.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy dịch vụ nào phù hợp.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final service = suggestionList[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (service['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(service['icon'], color: service['color']),
          ),
          title: Text(service['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            // Khi chọn vào 1 gợi ý, sẽ đóng search bar và nhảy tới PostJobScreen luôn
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PostJobScreen(selectedService: service['name']),
              ),
            );
          },
        );
      },
    );
  }
}