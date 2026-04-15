import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Timer? _locationUpdateTimer;
  Position? _lastPosition;

  // Kiểm tra và request permission
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra service có bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Kiểm tra permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Lấy vị trí hiện tại
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastPosition = position;
      return position;
    } catch (e) {
      print('Lỗi lấy location: $e');
      return null;
    }
  }

  // Bắt đầu tracking location (cập nhật mỗi 30 giây)
  void startLocationTracking() {
    _locationUpdateTimer?.cancel();

    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
          (timer) async {
        await _updateLocationToFirestore();
      },
    );

    // Cập nhật ngay lần đầu
    _updateLocationToFirestore();
  }

  // Dừng tracking
  void stopLocationTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  // Cập nhật vị trí lên Firestore
  Future<void> _updateLocationToFirestore() async {
    try {
      Position? position = await getCurrentLocation();
      if (position == null) return;

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Đã cập nhật vị trí: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Lỗi update location to Firestore: $e');
    }
  }

  // Stream vị trí realtime (cho map)
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Cập nhật khi di chuyển 10m
      ),
    );
  }

  // Tính khoảng cách giữa 2 điểm (km)
  double calculateDistance(
      double lat1,
      double lng1,
      double lat2,
      double lng2,
      ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  // Lấy địa chỉ từ tọa độ (Geocoding)
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      // TODO: Implement với Google Geocoding API hoặc package geocoding
      // Tạm thời return placeholder
      return 'Địa chỉ gần ($lat, $lng)';
    } catch (e) {
      print('Lỗi geocoding: $e');
      return 'Không xác định được địa chỉ';
    }
  }

  // Lấy last known position
  Position? get lastPosition => _lastPosition;

  // Clean up
  void dispose() {
    stopLocationTracking();
  }
}