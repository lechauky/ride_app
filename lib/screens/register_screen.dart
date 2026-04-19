import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'vehicle_info_screen.dart';

class RegisterScreen extends StatefulWidget {
  final int initialRole; // 0 = user, 1 = driver
  const RegisterScreen({super.key, this.initialRole = 0});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final hoTenCtl = TextEditingController();
  final emailCtl = TextEditingController();
  final sdtCtl = TextEditingController();
  final passCtl = TextEditingController();
  final rePassCtl = TextEditingController();

  late int role;
  String thanhPho = "HCM";
  bool obscurePass = true;
  bool obscureRePass = true;
  bool agree = false;

  @override
  void initState() {
    super.initState();
    role = widget.initialRole;
  }

  @override
  void dispose() {
    hoTenCtl.dispose();
    emailCtl.dispose();
    sdtCtl.dispose();
    passCtl.dispose();
    rePassCtl.dispose();
    super.dispose();
  }

  void _doRegister() {
    if (!_formKey.currentState!.validate()) return;
    if (!agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đồng ý với điều khoản")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đăng ký thành công!")),
    );

    // Nếu là tài xế, sang màn hình nhập thông tin xe
    if (role == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const VehicleInfoScreen(fromRegister: true),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng ký tài khoản"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chọn loại tài khoản
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
              const SizedBox(height: 20),

              _input(hoTenCtl, "Họ và tên", Icons.badge_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Bắt buộc nhập" : null),
              const SizedBox(height: 12),
              _input(emailCtl, "Email", Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                if (v == null || v.trim().isEmpty) return "Bắt buộc nhập";
                if (!v.contains("@")) return "Email không hợp lệ";
                return null;
              }),
              const SizedBox(height: 12),
              _input(sdtCtl, "Số điện thoại", Icons.phone_outlined,
                  keyboardType: TextInputType.phone, validator: (v) {
                if (v == null || v.trim().isEmpty) return "Bắt buộc nhập";
                if (v.trim().length < 9) return "SĐT không hợp lệ";
                return null;
              }),
              const SizedBox(height: 12),

              // Chọn thành phố
              DropdownButtonFormField<String>(
                initialValue: thanhPho,
                items: const [
                  DropdownMenuItem(value: "HCM", child: Text("TP. Hồ Chí Minh")),
                  DropdownMenuItem(value: "HN", child: Text("Hà Nội")),
                ],
                onChanged: (v) => setState(() => thanhPho = v!),
                decoration: InputDecoration(
                  labelText: "Thành phố hoạt động",
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),

              _passInput(passCtl, "Mật khẩu", obscurePass,
                  () => setState(() => obscurePass = !obscurePass),
                  validator: (v) {
                if (v == null || v.isEmpty) return "Bắt buộc nhập";
                if (v.length < 6) return "Tối thiểu 6 ký tự";
                return null;
              }),
              const SizedBox(height: 12),
              _passInput(rePassCtl, "Nhập lại mật khẩu", obscureRePass,
                  () => setState(() => obscureRePass = !obscureRePass),
                  validator: (v) {
                if (v != passCtl.text) return "Mật khẩu không khớp";
                return null;
              }),

              const SizedBox(height: 12),
              CheckboxListTile(
                value: agree,
                onChanged: (v) => setState(() => agree = v ?? false),
                title: const Text(
                    "Tôi đồng ý với Điều khoản & Chính sách bảo mật"),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _doRegister,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(role == 1
                    ? "Đăng ký & nhập thông tin xe"
                    : "Đăng ký"),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Đã có tài khoản? "),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Đăng nhập"),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _passInput(TextEditingController c, String label, bool obscure,
      VoidCallback toggle,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : Colors.black54),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
