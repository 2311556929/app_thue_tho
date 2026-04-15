import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  String id;
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
  final DateTime? scheduledTime;
  final double? estimatedPrice; // ✅ Thêm trường này

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
    this.scheduledTime,
    this.estimatedPrice, // ✅
  });

  factory Job.fromJson(Map<String, dynamic> json, String docId) {
    DateTime parsedCreatedAt = DateTime.now();
    if (json['createdAt'] != null) {
      parsedCreatedAt = (json['createdAt'] as Timestamp).toDate();
    }

    DateTime? parsedScheduledTime;
    if (json['scheduledTime'] != null) {
      if (json['scheduledTime'] is Timestamp) {
        parsedScheduledTime = (json['scheduledTime'] as Timestamp).toDate();
      } else {
        parsedScheduledTime = DateTime.tryParse(json['scheduledTime'].toString());
      }
    }

    return Job(
      id: docId,
      customerId: json['customerId'] ?? '',
      serviceType: json['serviceType'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      customerAddress: json['customerAddress'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: parsedCreatedAt,
      scheduledTime: parsedScheduledTime,
      estimatedPrice: (json['estimatedPrice'] ?? 0).toDouble(), // ✅
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledTime': scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,
      'estimatedPrice': estimatedPrice, // ✅
    };
  }
}