import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appthuetho/controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String selectedRole = 'customer';
  bool _isObscure = true; // Biến để ẩn/hiện mật khẩu

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // Hàm tiện ích tạo TextField đẹp mắt
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? _isObscure : false,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isObscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _isObscure = !_isObscure;
              });
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  // Hàm tiện ích tạo Card chọn vai trò (Role)
  Widget _buildRoleCard(String title, String value, IconData icon) {
    bool isSelected = selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.blueAccent : Colors.grey.shade500),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.blueAccent : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Tạo tài khoản',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng điền thông tin bên dưới để bắt đầu sử dụng dịch vụ của chúng tôi.',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),

              // Form Inputs
              _buildTextField(
                controller: nameController,
                label: 'Họ và tên',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: phoneController,
                label: 'Số điện thoại',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: passwordController,
                label: 'Mật khẩu',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 24),

              // Phân quyền (Role Selection)
              Text(
                'Bạn là:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildRoleCard('Khách hàng', 'customer', Icons.supervised_user_circle_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildRoleCard('Thợ', 'provider', Icons.handyman_outlined)),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: authController.isLoading
                      ? null
                      : () async {
                    // Tắt bàn phím khi bấm đăng ký
                    FocusScope.of(context).unfocus();

                    String name = nameController.text.trim();
                    String email = emailController.text.trim();
                    String password = passwordController.text.trim();
                    String phone = phoneController.text.trim();

                    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Vui lòng nhập đầy đủ thông tin'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      return;
                    }

                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Mật khẩu phải có ít nhất 6 ký tự'),
                          backgroundColor: Colors.orangeAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      return;
                    }

                    await authController.registerWithEmail(
                        email, password, name, phone, selectedRole, context);
                  },
                  child: authController.isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'ĐĂNG KÝ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Nút Chuyển Hướng Đăng Nhập
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Đã có tài khoản? ',
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                      children: [
                        TextSpan(
                          text: 'Đăng nhập',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}