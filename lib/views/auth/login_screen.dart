// lib/views/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _anim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header gradient ──────────────────────────
              Container(
                width: double.infinity,
                height: size.height * 0.38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00AEEF), Color(0xFF0057B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.handyman_rounded,
                          color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'App Thuê Thợ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kết nối thợ chuyên nghiệp tận nhà',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                    const SizedBox(height: 28),

                    // Email
                    _buildField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'example@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _buildField(
                      controller: _passCtrl,
                      label: 'Mật khẩu',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),

                    // Quên mật khẩu
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen()),
                        ),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: Color(0xFF00AEEF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Nút đăng nhập
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00AEEF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: auth.isLoading
                            ? null
                            : () {
                          final email = _emailCtrl.text.trim();
                          final pass = _passCtrl.text.trim();
                          if (email.isEmpty || pass.isEmpty) {
                            _snack('Vui lòng nhập đầy đủ thông tin');
                            return;
                          }
                          auth.loginWithEmail(email, pass, context);
                        },
                        child: auth.isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                            : const Text(
                          'ĐĂNG NHẬP',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Row(children: [
                      Expanded(child: Divider(color: Colors.grey[200])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('hoặc',
                            style: TextStyle(color: Colors.grey[400])),
                      ),
                      Expanded(child: Divider(color: Colors.grey[200])),
                    ]),
                    const SizedBox(height: 20),

                    // Đăng ký
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00AEEF),
                          side: const BorderSide(
                              color: Color(0xFF00AEEF), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text(
                          'TẠO TÀI KHOẢN MỚI',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[350], fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF6F8FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Color(0xFF00AEEF), width: 1.5),
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}