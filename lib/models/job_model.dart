class Job {
  final String? id;
  final String customerId;           // Sau này lấy từ auth
  final String serviceType;          // Tủ lạnh, Máy giặt...
  final String description;
  final String? imagePath;           // Đường dẫn ảnh
  final double latitude;
  final double longitude;
  final String status;               // 'pending', 'finding', 'accepted'...

  Job({
    this.id,
    required this.customerId,
    required this.serviceType,
    required this.description,
    this.imagePath,
    required this.latitude,
    required this.longitude,
    this.status = 'pending',
  });

  // Chuyển sang JSON để gửi lên server
  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'serviceType': serviceType,
      'description': description,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}