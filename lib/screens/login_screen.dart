import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_store.dart';
import 'home_screen.dart';
import 'driver_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtl = TextEditingController();
  final TextEditingController passCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 0 = Người dùng, 1 = Tài xế
  int role = 0;
  bool obscurePass = true;
  String city = "HCM";
  bool isProcessing = false;

  @override
  void dispose() {
    emailCtl.dispose();
    passCtl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isProcessing = true);

    try {
      final res = await ApiService.post('auth/login', 'HCM', {
        // Mặc định gọi cổng 5001 để login
        "email": emailCtl.text.trim(),
        "mat_khau": passCtl.text,
      });

      final data = res["data"];
      if (data["success"] == true) {
        final userData = data["data"];
        final dbRole = userData["vai_tro"]?.toString() == "driver" ? 1 : 0;
        await AuthStore.login(
          UserInfo(
            id: userData["id"].toString(),
            email: userData["email"].toString(),
            hoTen: userData["ho_ten"].toString(),
            thanhPho: (userData["thanh_pho"] ?? 'HCM').toString(),
            role: dbRole,
          ),
          data["token"].toString(),
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đăng nhập thành công")));

        if (!mounted) return;
        if (dbRole == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Đăng nhập thất bại")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car_filled,
                    size: 54,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    "Ride App",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const Center(
                  child: Text(
                    "Đăng nhập để tiếp tục",
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 28),

                // Toggle người dùng / tài xế
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _roleTab("Người dùng", 0, Icons.person),
                      _roleTab("Tài xế", 1, Icons.drive_eta),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Vui lòng nhập email";
                    }
                    if (!v.contains("@")) return "Email không hợp lệ";
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: passCtl,
                  obscureText: obscurePass,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => obscurePass = !obscurePass),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Vui lòng nhập mật khẩu";
                    if (v.length < 6) return "Mật khẩu tối thiểu 6 ký tự";
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("Quên mật khẩu?"),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: isProcessing ? null : _doLogin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Đăng nhập", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Chưa có tài khoản? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(initialRole: role),
                          ),
                        );
                      },
                      child: const Text("Đăng ký ngay"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String label, int value, IconData icon) {
    final selected = role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.deepPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
