import 'package:flutter/material.dart';
import 'payment_screen.dart';

class RideType {
  final String id;
  final String tenLoai;
  final IconData icon;
  final int giaCoBan; // VNĐ
  final int giaMoiKm; // VNĐ
  final String moTa;
  final int sucChua;

  RideType({
    required this.id,
    required this.tenLoai,
    required this.icon,
    required this.giaCoBan,
    required this.giaMoiKm,
    required this.moTa,
    required this.sucChua,
  });
}

class RideTypesScreen extends StatefulWidget {
  // Khoảng cách giả định (km) – có thể truyền từ booking
  final double khoangCachKm;
  const RideTypesScreen({super.key, this.khoangCachKm = 5.0});

  @override
  State<RideTypesScreen> createState() => _RideTypesScreenState();
}

class _RideTypesScreenState extends State<RideTypesScreen> {
  final List<RideType> rideTypes = [
    RideType(
      id: "bike",
      tenLoai: "Xe máy",
      icon: Icons.two_wheeler,
      giaCoBan: 12000,
      giaMoiKm: 4000,
      moTa: "Nhanh, tiện cho 1 người",
      sucChua: 1,
    ),
    RideType(
      id: "car4",
      tenLoai: "Ô tô 4 chỗ",
      icon: Icons.directions_car,
      giaCoBan: 25000,
      giaMoiKm: 11000,
      moTa: "Phù hợp 1-3 người",
      sucChua: 3,
    ),
    RideType(
      id: "car7",
      tenLoai: "Ô tô 7 chỗ",
      icon: Icons.airport_shuttle,
      giaCoBan: 35000,
      giaMoiKm: 15000,
      moTa: "Gia đình hoặc nhóm bạn",
      sucChua: 6,
    ),
  ];

  int selectedIndex = 0;

  String _formatVND(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return "${buf.toString()}₫";
  }

  int _tongTien(RideType t) =>
      (t.giaCoBan + (t.giaMoiKm * widget.khoangCachKm)).toInt();

  @override
  Widget build(BuildContext context) {
    final selected = rideTypes[selectedIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn loại xe"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.straighten,
                        color: Colors.deepPurple, size: 20),
                    const SizedBox(width: 6),
                    Text("Khoảng cách: ${widget.khoangCachKm} km",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Vui lòng chọn loại xe phù hợp",
                    style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rideTypes.length,
              itemBuilder: (_, i) {
                final t = rideTypes[i];
                final isSelected = i == selectedIndex;
                return GestureDetector(
                  onTap: () => setState(() => selectedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurple.shade50
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Colors.deepPurple.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isSelected
                              ? Colors.deepPurple
                              : Colors.grey.shade200,
                          child: Icon(
                            t.icon,
                            color: isSelected
                                ? Colors.white
                                : Colors.deepPurple,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    t.tenLoai,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person,
                                            size: 12,
                                            color: Colors.black54),
                                        Text(" ${t.sucChua}",
                                            style: const TextStyle(
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(t.moTa,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(
                                "Mở cửa ${_formatVND(t.giaCoBan)} • ${_formatVND(t.giaMoiKm)}/km",
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatVND(_tongTien(t)),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.black87,
                              ),
                            ),
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(Icons.check_circle,
                                    color: Colors.deepPurple),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer xác nhận
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, -2))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tổng cước (${selected.tenLoai})",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54)),
                    Text(_formatVND(_tongTien(selected)),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple)),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(
                          tongTien: _tongTien(selected),
                          tenLoaiXe: selected.tenLoai,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Tiếp tục thanh toán",
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
