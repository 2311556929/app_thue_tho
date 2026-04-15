class AppUser {
  final String id;
  final String phone;
  final String name;
  final String role; // 'customer' hoặc 'provider'
  final String? avatar;
  final bool isVerified;

  // Thêm các trường mới cho dữ liệu thật
  final String email;
  final int completedOrders;
  final int usedTechnicians;
  final int points;


  AppUser({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    this.avatar,
    this.isVerified = false,
    required this.email,
    this.completedOrders = 0, // Mặc định là 0
    this.usedTechnicians = 0, // Mặc định là 0
    this.points = 0,          // Mặc định là 0

  });

  // Chuyển từ JSON (Firestore/API) sang Object
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      // Lấy 'id' hoặc 'uid' vì đôi khi lưu trên Firestore là uid
      id: json['id'] ?? json['uid'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'customer',
      avatar: json['avatar'],
      isVerified: json['isVerified'] ?? false,
      email: json['email'] ?? '',
      completedOrders: json['completedOrders'] ?? 0,
      usedTechnicians: json['usedTechnicians'] ?? 0,
      points: json['points'] ?? 0,
    );
  }

  // Chuyển từ Object sang JSON để đẩy lên Firestore/API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'role': role,
      'avatar': avatar,
      'isVerified': isVerified,
      'email': email,
      'completedOrders': completedOrders,
      'usedTechnicians': usedTechnicians,
      'points': points,
    };
  }

  // Hàm copyWith giúp cập nhật một phần dữ liệu
  AppUser copyWith({
    String? id,
    String? phone,
    String? name,
    String? role,
    String? avatar,
    bool? isVerified,
    String? email,
    int? completedOrders,
    int? usedTechnicians,
    int? points,
  }) {
    return AppUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      isVerified: isVerified ?? this.isVerified,
      email: email ?? this.email,
      completedOrders: completedOrders ?? this.completedOrders,
      usedTechnicians: usedTechnicians ?? this.usedTechnicians,
      points: points ?? this.points,
    );
  }
}