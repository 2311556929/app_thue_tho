import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _myVouchers = [
    {
      'code': 'WELCOME50',
      'title': 'Giảm 50k cho đơn đầu tiên',
      'description': 'Áp dụng cho đơn hàng từ 200k',
      'discount': '50.000đ',
      'expiry': '31/12/2026',
      'minOrder': '200.000đ',
      'type': 'discount',
    },
    {
      'code': 'FREESHIP',
      'title': 'Miễn phí di chuyển',
      'description': 'Miễn phí phí di chuyển trong 5km',
      'discount': 'Free',
      'expiry': '30/11/2026',
      'minOrder': '0đ',
      'type': 'freeship',
    },
  ];

  final List<Map<String, dynamic>> _availableVouchers = [
    {
      'code': 'TAIKHOAN100',
      'title': 'Giảm 100k cho tài khoản mới',
      'description': 'Dành cho khách hàng mới đăng ký',
      'discount': '100.000đ',
      'expiry': '31/12/2026',
      'minOrder': '300.000đ',
      'type': 'discount',
    },
    {
      'code': 'WEEKEND20',
      'title': 'Giảm 20% cuối tuần',
      'description': 'Áp dụng T7, CN',
      'discount': '20%',
      'expiry': '31/12/2026',
      'minOrder': '150.000đ',
      'type': 'discount',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _copyVoucherCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã: $code'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _collectVoucher(Map<String, dynamic> voucher) {
    setState(() {
      _myVouchers.add(voucher);
      _availableVouchers.remove(voucher);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu voucher: ${voucher['code']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Voucher'),
        backgroundColor: const Color(0xFF00AEEF),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Voucher của tôi'),
            Tab(text: 'Voucher có sẵn'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyVouchers(),
          _buildAvailableVouchers(),
        ],
      ),
    );
  }

  Widget _buildMyVouchers() {
    if (_myVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có voucher nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lưu voucher từ tab "Voucher có sẵn"',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myVouchers.length,
      itemBuilder: (context, index) {
        return _buildVoucherCard(_myVouchers[index], isMyVoucher: true);
      },
    );
  }

  Widget _buildAvailableVouchers() {
    if (_availableVouchers.isEmpty) {
      return const Center(
        child: Text('Không có voucher khả dụng'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableVouchers.length,
      itemBuilder: (context, index) {
        return _buildVoucherCard(_availableVouchers[index], isMyVoucher: false);
      },
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher, {required bool isMyVoucher}) {
    final isDiscount = voucher['type'] == 'discount';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDiscount
              ? [const Color(0xFF00AEEF), const Color(0xFF0086c3)]
              : [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDiscount
                ? const Color(0xFF00AEEF).withOpacity(0.3)
                : Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Dashed border effect
            Positioned.fill(
              child: CustomPaint(
                painter: DashedBorderPainter(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isDiscount ? Icons.local_offer : Icons.local_shipping,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voucher['discount'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              voucher['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    voucher['description'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(Icons.shopping_bag, color: Colors.white.withOpacity(0.7), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Đơn tối thiểu: ${voucher['minOrder']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time, color: Colors.white.withOpacity(0.7), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'HSD: ${voucher['expiry']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            voucher['code'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        if (isMyVoucher)
                          InkWell(
                            onTap: () => _copyVoucherCode(voucher['code']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00AEEF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.copy, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Sao chép',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          InkWell(
                            onTap: () => _collectVoucher(voucher),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.add, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Lưu',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 10;
    const dashSpace = 5;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}