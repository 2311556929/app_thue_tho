import 'dart:async';
import 'dart:math';

import 'package:app_thuetho_provider/models/order_model.dart';


class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  // Stream để phát đơn hàng mới
  final StreamController<List<ServiceOrder>> _ordersController = StreamController<List<ServiceOrder>>.broadcast();
  Stream<List<ServiceOrder>> get ordersStream => _ordersController.stream;

  final StreamController<int> _newOrdersCountController = StreamController<int>.broadcast();
  Stream<int> get newOrdersCountStream => _newOrdersCountController.stream;

  // Danh sách đơn hàng (giả lập database)
  final List<ServiceOrder> _allOrders = [];
  final List<ServiceOrder> _pendingOrders = [];
  final List<ServiceOrder> _myAcceptedOrders = [];

  // Vị trí hiện tại của thợ (giả lập)
  double _providerLat = 10.7769; // Vị trí mẫu ở HCM
  double _providerLng = 106.7009;

  void updateProviderLocation(double lat, double lng) {
    _providerLat = lat;
    _providerLng = lng;
  }

  // Khởi tạo đơn hàng mẫu
  void initializeSampleOrders() {
    _allOrders.clear();
    _pendingOrders.clear();

    final sampleOrders = [
      ServiceOrder(
        id: 'ORD001',
        customerId: 'CUST001',
        customerName: 'Nguyễn Văn A',
        customerPhone: '0901234567',
        customerAvatar: 'https://i.pravatar.cc/150?img=1',
        serviceType: 'plumbing',
        serviceTitle: 'Sửa vòi nước bị rò rỉ',
        description: 'Vòi nước ở bồn rửa chén bị rò rỉ nước, cần thợ đến sửa gấp.',
        address: '123 Nguyễn Huệ, Quận 1, TP.HCM',
        latitude: 10.7755 + (Random().nextDouble() - 0.5) * 0.01,
        longitude: 106.7010 + (Random().nextDouble() - 0.5) * 0.01,
        estimatedPrice: 150000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: OrderStatus.pending,
        customerRating: 4.8,
        distance: _calculateDistance(10.7755, 106.7010),
      ),
      ServiceOrder(
        id: 'ORD002',
        customerId: 'CUST002',
        customerName: 'Trần Thị B',
        customerPhone: '0912345678',
        customerAvatar: 'https://i.pravatar.cc/150?img=2',
        serviceType: 'electrical',
        serviceTitle: 'Thay bóng đèn LED',
        description: 'Cần thay 3 bóng đèn LED ở phòng khách và phòng ngủ.',
        address: '456 Lê Lợi, Quận 1, TP.HCM',
        latitude: 10.7780 + (Random().nextDouble() - 0.5) * 0.01,
        longitude: 106.7000 + (Random().nextDouble() - 0.5) * 0.01,
        estimatedPrice: 200000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        status: OrderStatus.pending,
        customerRating: 4.5,
        distance: _calculateDistance(10.7780, 106.7000),
      ),
      ServiceOrder(
        id: 'ORD003',
        customerId: 'CUST003',
        customerName: 'Lê Văn C',
        customerPhone: '0923456789',
        customerAvatar: 'https://i.pravatar.cc/150?img=3',
        serviceType: 'cleaning',
        serviceTitle: 'Vệ sinh máy lạnh',
        description: 'Máy lạnh phòng ngủ cần vệ sinh bảo dưỡng định kỳ.',
        address: '789 Pasteur, Quận 3, TP.HCM',
        latitude: 10.7760 + (Random().nextDouble() - 0.5) * 0.01,
        longitude: 106.7020 + (Random().nextDouble() - 0.5) * 0.01,
        estimatedPrice: 300000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        status: OrderStatus.pending,
        customerRating: 4.9,
        distance: _calculateDistance(10.7760, 106.7020),
      ),
      ServiceOrder(
        id: 'ORD004',
        customerId: 'CUST004',
        customerName: 'Phạm Thị D',
        customerPhone: '0934567890',
        customerAvatar: 'https://i.pravatar.cc/150?img=4',
        serviceType: 'plumbing',
        serviceTitle: 'Thông tắc bồn cầu',
        description: 'Bồn cầu bị tắc nghẽn, cần thợ đến thông gấp.',
        address: '321 Võ Văn Tần, Quận 3, TP.HCM',
        latitude: 10.7770 + (Random().nextDouble() - 0.5) * 0.01,
        longitude: 106.7030 + (Random().nextDouble() - 0.5) * 0.01,
        estimatedPrice: 250000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        status: OrderStatus.pending,
        customerRating: 4.7,
        distance: _calculateDistance(10.7770, 106.7030),
      ),
    ];

    _allOrders.addAll(sampleOrders);
    _pendingOrders.addAll(sampleOrders);
    _notifyOrdersChanged();
  }

  // Tính khoảng cách giữa 2 điểm (công thức Haversine đơn giản hóa)
  double _calculateDistance(double lat, double lng) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat - _providerLat);
    double dLng = _toRadians(lng - _providerLng);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(_providerLat)) * cos(_toRadians(lat)) *
            sin(dLng / 2) * sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // Lấy danh sách đơn chờ
  List<ServiceOrder> getPendingOrders() {
    return _pendingOrders;
  }

  // Lấy danh sách đơn đã nhận
  List<ServiceOrder> getMyAcceptedOrders() {
    return _myAcceptedOrders;
  }

  // Nhận đơn
  Future<bool> acceptOrder(String orderId, String providerId, String providerName) async {
    // Giả lập delay network
    await Future.delayed(const Duration(milliseconds: 500));

    final orderIndex = _pendingOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return false;

    final order = _pendingOrders[orderIndex];
    final acceptedOrder = order.copyWith(
      status: OrderStatus.accepted,
      providerId: providerId,
      providerName: providerName,
    );

    _pendingOrders.removeAt(orderIndex);
    _myAcceptedOrders.add(acceptedOrder);

    // Cập nhật trong danh sách tất cả đơn
    final allOrderIndex = _allOrders.indexWhere((o) => o.id == orderId);
    if (allOrderIndex != -1) {
      _allOrders[allOrderIndex] = acceptedOrder;
    }

    _notifyOrdersChanged();
    return true;
  }

  // Từ chối đơn
  Future<bool> rejectOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Chỉ xóa khỏi danh sách pending của thợ này
    _pendingOrders.removeWhere((o) => o.id == orderId);
    _notifyOrdersChanged();
    return true;
  }

  // Bắt đầu thực hiện đơn
  Future<bool> startOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final orderIndex = _myAcceptedOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return false;

    final order = _myAcceptedOrders[orderIndex];
    final updatedOrder = order.copyWith(status: OrderStatus.inProgress);

    _myAcceptedOrders[orderIndex] = updatedOrder;

    final allOrderIndex = _allOrders.indexWhere((o) => o.id == orderId);
    if (allOrderIndex != -1) {
      _allOrders[allOrderIndex] = updatedOrder;
    }

    _notifyOrdersChanged();
    return true;
  }

  // Hoàn thành đơn
  Future<bool> completeOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final orderIndex = _myAcceptedOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return false;

    final order = _myAcceptedOrders[orderIndex];
    final updatedOrder = order.copyWith(status: OrderStatus.completed);

    _myAcceptedOrders[orderIndex] = updatedOrder;

    final allOrderIndex = _allOrders.indexWhere((o) => o.id == orderId);
    if (allOrderIndex != -1) {
      _allOrders[allOrderIndex] = updatedOrder;
    }

    _notifyOrdersChanged();
    return true;
  }

  // Tạo đơn mới (simulation - có thể được gọi định kỳ)
  void generateNewOrder() {
    final newOrder = ServiceOrder(
      id: 'ORD${DateTime.now().millisecondsSinceEpoch}',
      customerId: 'CUST${Random().nextInt(1000)}',
      customerName: _randomCustomerName(),
      customerPhone: '09${Random().nextInt(100000000).toString().padLeft(8, '0')}',
      customerAvatar: 'https://i.pravatar.cc/150?img=${Random().nextInt(70)}',
      serviceType: ['plumbing', 'electrical', 'cleaning'][Random().nextInt(3)],
      serviceTitle: _randomServiceTitle(),
      description: 'Cần thợ đến sửa chữa ngay.',
      address: '${Random().nextInt(999)} Đường ABC, Quận ${Random().nextInt(12) + 1}, TP.HCM',
      latitude: 10.7769 + (Random().nextDouble() - 0.5) * 0.02,
      longitude: 106.7009 + (Random().nextDouble() - 0.5) * 0.02,
      estimatedPrice: (Random().nextInt(20) + 10) * 10000.0,
      createdAt: DateTime.now(),
      status: OrderStatus.pending,
      customerRating: 4.0 + Random().nextDouble(),
      distance: Random().nextDouble() * 5, // 0-5km
    );

    _allOrders.add(newOrder);
    _pendingOrders.add(newOrder);
    _notifyOrdersChanged();
  }

  String _randomCustomerName() {
    final firstNames = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Phan', 'Vũ', 'Đặng'];
    final middleNames = ['Văn', 'Thị', 'Minh', 'Hồng', 'Anh', 'Tuấn', 'Thu'];
    final lastNames = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'Hải', 'Nam', 'Phương', 'Linh'];

    return '${firstNames[Random().nextInt(firstNames.length)]} ${middleNames[Random().nextInt(middleNames.length)]} ${lastNames[Random().nextInt(lastNames.length)]}';
  }

  String _randomServiceTitle() {
    final titles = [
      'Sửa vòi nước bị rò rỉ',
      'Thay bóng đèn LED',
      'Vệ sinh máy lạnh',
      'Thông tắc bồn cầu',
      'Sửa ổ cắm điện',
      'Lắp quạt trần',
      'Sửa máy bơm nước',
      'Thay cầu dao',
    ];
    return titles[Random().nextInt(titles.length)];
  }

  void _notifyOrdersChanged() {
    _ordersController.add(_pendingOrders);
    _newOrdersCountController.add(_pendingOrders.length);
  }

  void dispose() {
    _ordersController.close();
    _newOrdersCountController.close();
  }
}