import 'package:appthuetho/controllers/auth_controller.dart';
import 'package:appthuetho/services/location_service.dart';
import 'package:appthuetho/views/auth/login_screen.dart';
import 'package:appthuetho/views/provider/provider_main_screen.dart';
import 'package:appthuetho/views/provider/provider_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        // Đây chính là thứ mà cái màn hình đỏ đang đòi
        ChangeNotifierProvider(create: (_) => AuthController()),
        // Nếu bạn có thêm JobController hay ProfileController thì thêm vào đây:
        // ChangeNotifierProvider(create: (_) => JobController()),
      ],
      child: const ProviderApp(),
    ),
  );
}
class ProviderApp extends StatelessWidget {
  const ProviderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Thuê Thợ - Thợ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF00AEEF),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00AEEF),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final LocationService _locationService = LocationService();
  final ProviderProfileService _profileService = ProviderProfileService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Request location permission
    bool hasPermission = await _locationService.requestLocationPermission();
    if (!hasPermission) {
      print('⚠️ Location permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Đã đăng nhập
          return const ProviderMainScreenWrapper();
        }

        // Chưa đăng nhập
        return const LoginScreen();
      },
    );
  }
}

class ProviderMainScreenWrapper extends StatefulWidget {
  const ProviderMainScreenWrapper({super.key});

  @override
  State<ProviderMainScreenWrapper> createState() => _ProviderMainScreenWrapperState();
}

class _ProviderMainScreenWrapperState extends State<ProviderMainScreenWrapper> with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  final ProviderProfileService _profileService = ProviderProfileService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLocationTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationTracking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App quay lại foreground
      _profileService.updateOnlineStatus(true);
      _startLocationTracking();
    } else if (state == AppLifecycleState.paused) {
      // App vào background
      _profileService.updateOnlineStatus(false);
      _stopLocationTracking();
    }
  }

  void _startLocationTracking() {
    _locationService.startLocationTracking();
  }

  void _stopLocationTracking() {
    _locationService.stopLocationTracking();
  }

  @override
  Widget build(BuildContext context) {
    return const ProviderMainScreen();
  }
}