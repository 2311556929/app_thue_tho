import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_thuetho_provider/controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController(); // THÊM CONTROLLER SĐT
  String selectedRole = 'customer';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose(); // THÊM DISPOSE
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tạo tài khoản', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 16),

            // THÊM Ô NHẬP SỐ ĐIỆN THOẠI
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu (ít nhất 6 ký tự)',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Chọn vai trò
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text('Khách hàng'),
                    value: 'customer',
                    groupValue: selectedRole,
                    onChanged: (value) => setState(() => selectedRole = value.toString()),
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text('Thợ'),
                    value: 'provider',
                    groupValue: selectedRole,
                    onChanged: (value) => setState(() => selectedRole = value.toString()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: authController.isLoading
                    ? null
                    : () async {
                  String name = nameController.text.trim();
                  String email = emailController.text.trim();
                  String password = passwordController.text.trim();
                  String phone = phoneController.text.trim(); // LẤY SĐT

                  if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                    );
                    return;
                  }

                  if (password.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')),
                    );
                    return;
                  }

                  // GỌI HÀM ĐĂNG KÝ VỚI BIẾN PHONE ĐÃ THÊM
                  await authController.registerWithEmail(email, password, name, phone, selectedRole, context);
                },
                child: authController.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ĐĂNG KÝ', style: TextStyle(fontSize: 18)),
              ),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}