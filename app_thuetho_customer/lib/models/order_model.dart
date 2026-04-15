class ServiceOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAvatar;
  final String serviceType; // 'plumbing', 'electrical', 'cleaning', etc.
  final String serviceTitle;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final double estimatedPrice;
  final DateTime createdAt;
  final DateTime? scheduledTime;
  final OrderStatus status;
  final String? providerId; // ID của thợ nhận đơn
  final String? providerName;
  final double? customerRating;
  final double distance; // Khoảng cách từ thợ (km)

  ServiceOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAvatar,
    required this.serviceType,
    required this.serviceTitle,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.estimatedPrice,
    required this.createdAt,
    this.scheduledTime,
    required this.status,
    this.providerId,
    this.providerName,
    this.customerRating,
    required this.distance,
  });

  ServiceOrder copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAvatar,
    String? serviceType,
    String? serviceTitle,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    double? estimatedPrice,
    DateTime? createdAt,
    DateTime? scheduledTime,
    OrderStatus? status,
    String? providerId,
    String? providerName,
    double? customerRating,
    double? distance,
  }) {
    return ServiceOrder(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAvatar: customerAvatar ?? this.customerAvatar,
      serviceType: serviceType ?? this.serviceType,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      createdAt: createdAt ?? this.createdAt,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      customerRating: customerRating ?? this.customerRating,
      distance: distance ?? this.distance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAvatar': customerAvatar,
      'serviceType': serviceType,
      'serviceTitle': serviceTitle,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'estimatedPrice': estimatedPrice,
      'createdAt': createdAt.toIso8601String(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'status': status.toString(),
      'providerId': providerId,
      'providerName': providerName,
      'customerRating': customerRating,
      'distance': distance,
    };
  }

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    return ServiceOrder(
      id: json['id'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerAvatar: json['customerAvatar'],
      serviceType: json['serviceType'],
      serviceTitle: json['serviceTitle'],
      description: json['description'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      estimatedPrice: json['estimatedPrice'],
      createdAt: DateTime.parse(json['createdAt']),
      scheduledTime: json['scheduledTime'] != null ? DateTime.parse(json['scheduledTime']) : null,
      status: OrderStatus.values.firstWhere((e) => e.toString() == json['status']),
      providerId: json['providerId'],
      providerName: json['providerName'],
      customerRating: json['customerRating'],
      distance: json['distance'],
    );
  }
}

enum OrderStatus {
  pending, // Đơn mới, chưa có thợ nhận
  accepted, // Thợ đã nhận đơn
  inProgress, // Đang thực hiện
  completed, // Hoàn thành
  cancelled, // Đã hủy
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Đang tìm thợ';
      case OrderStatus.accepted:
        return 'Đã nhận đơn';
      case OrderStatus.inProgress:
        return 'Đang thực hiện';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  String get colorHex {
    switch (this) {
      case OrderStatus.pending:
        return '#FFA500';
      case OrderStatus.accepted:
        return '#00AEEF';
      case OrderStatus.inProgress:
        return '#4CAF50';
      case OrderStatus.completed:
        return '#757575';
      case OrderStatus.cancelled:
        return '#F44336';
    }
  }
}