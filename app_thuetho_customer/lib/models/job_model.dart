class Job {
  final String id;
  final String customerId;
  final String serviceType;
  final String description;
  final String? imagePath;
  final double latitude;
  final double longitude;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String status;
  final DateTime createdAt;
  final DateTime? scheduledTime;   // ✅ Thêm dòng này

  Job({
    required this.id,
    required this.customerId,
    required this.serviceType,
    required this.description,
    this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.status = 'pending',
    required this.createdAt,
    this.scheduledTime,            // ✅ Thêm vào constructor


  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      customerId: json['customerId'],
      serviceType: json['serviceType'],
      description: json['description'],
      imagePath: json['imagePath'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      customerAddress: json['customerAddress'] ?? '',
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Hàm này chuyển đổi đối tượng Job thành định dạng JSON
  // để gửi qua API lên server mà không bị báo lỗi đỏ
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'serviceType': serviceType,
      'description': description,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}