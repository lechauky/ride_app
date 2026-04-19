import 'package:flutter/material.dart';
import 'driver_home_screen.dart';

class VehicleInfoScreen extends StatefulWidget {
  final bool fromRegister;
  const VehicleInfoScreen({super.key, this.fromRegister = false});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final bienSoCtl = TextEditingController();
  final hangXeCtl = TextEditingController();
  final mauXeCtl = TextEditingController();
  final namSXCtl = TextEditingController();

  String loaiXe = "xe_may";
  bool dangHoatDong = true;

  final loaiXeList = const [
    {"value": "xe_may", "label": "Xe máy", "icon": Icons.two_wheeler},
    {"value": "o_to_4_cho", "label": "Ô tô 4 chỗ", "icon": Icons.directions_car},
    {"value": "o_to_7_cho", "label": "Ô tô 7 chỗ", "icon": Icons.airport_shuttle},
  ];

  @override
  void dispose() {
    bienSoCtl.dispose();
    hangXeCtl.dispose();
    mauXeCtl.dispose();
    namSXCtl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 26),
            SizedBox(width: 8),
            Text("Lưu thành công"),
          ],
        ),
        content: Text(
            "Đã thêm phương tiện ${bienSoCtl.text.toUpperCase()} vào hồ sơ tài xế."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.fromRegister) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DriverHomeScreen()),
                  (r) => false,
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin phương tiện"),
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
              // Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline,
                        color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Vui lòng nhập chính xác thông tin xe để khách hàng dễ nhận diện.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Loại xe
              const Text("Loại xe",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: loaiXeList.map((opt) {
                  final isSel = opt["value"] == loaiXe;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => loaiXe = opt["value"] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSel
                                ? Colors.deepPurple
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel
                                  ? Colors.deepPurple
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(opt["icon"] as IconData,
                                  color: isSel
                                      ? Colors.white
                                      : Colors.deepPurple),
                              const SizedBox(height: 4),
                              Text(
                                opt["label"] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSel
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              _input(bienSoCtl, "Biển số xe", Icons.confirmation_number,
                  hint: "VD: 59X1-234.56", validator: (v) {
                if (v == null || v.trim().isEmpty) return "Bắt buộc nhập";
                if (v.trim().length < 5) return "Biển số không hợp lệ";
                return null;
              }),
              const SizedBox(height: 12),
              _input(hangXeCtl, "Hãng xe", Icons.business,
                  hint: "VD: Honda, Toyota, Yamaha",
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Bắt buộc nhập" : null),
              const SizedBox(height: 12),
              _input(mauXeCtl, "Màu xe", Icons.color_lens,
                  hint: "VD: Đen, Trắng, Đỏ",
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Bắt buộc nhập" : null),
              const SizedBox(height: 12),
              _input(namSXCtl, "Năm sản xuất", Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  hint: "VD: 2022", validator: (v) {
                if (v == null || v.trim().isEmpty) return "Bắt buộc nhập";
                final n = int.tryParse(v);
                if (n == null) return "Phải là số";
                final cur = DateTime.now().year;
                if (n < 1980 || n > cur) {
                  return "Năm phải từ 1980 đến $cur";
                }
                return null;
              }),
              const SizedBox(height: 12),

              SwitchListTile(
                value: dangHoatDong,
                onChanged: (v) => setState(() => dangHoatDong = v),
                title: const Text("Đang sử dụng",
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(dangHoatDong
                    ? "Xe sẵn sàng nhận chuyến"
                    : "Tạm dừng — không nhận chuyến"),
                activeThumbColor: Colors.deepPurple,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text("Lưu phương tiện"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon,
      {String? hint,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
