import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/active_trip_store.dart';
import 'passenger_trip_screen.dart';

class PaymentMethod {
  final String id;
  final String ten;
  final IconData icon;
  final Color color;
  final String moTa;
  PaymentMethod(this.id, this.ten, this.icon, this.color, this.moTa);
}

class PaymentScreen extends StatefulWidget {
  final int tongTien;
  final String tenLoaiXe;
  final double khoangCachKm;
  final String? diaChiDon;
  final String? diaChiDen;
  final LatLng? diemDon;
  final LatLng? diemDen;

  const PaymentScreen({
    super.key,
    required this.tongTien,
    required this.tenLoaiXe,
    this.khoangCachKm = 5.0,
    this.diaChiDon,
    this.diaChiDen,
    this.diemDon,
    this.diemDen,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final methods = [
    PaymentMethod("tien_mat", "Tiền mặt", Icons.payments, Colors.green,
        "Thanh toán khi kết thúc chuyến"),
    PaymentMethod("vi_dien_tu", "Ví điện tử", Icons.account_balance_wallet,
        Colors.orange, "Momo / ZaloPay / VNPay"),
    PaymentMethod("the_ngan_hang", "Thẻ ngân hàng", Icons.credit_card,
        Colors.blue, "Visa / MasterCard / ATM nội địa"),
  ];

  int selected = 0;
  bool isProcessing = false;

  String _formatVND(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return "${buf.toString()}₫";
  }

  /// Khởi tạo trip giả lập sau khi thanh toán thành công
  PassengerTripInfo _createTrip() {
    final maChuyen =
        "${DateTime.now().millisecondsSinceEpoch % 1000000}";
    return PassengerTripInfo(
      maChuyenDi: maChuyen,
      tenTaiXe: "Nguyễn Văn A",
      sdtTaiXe: "0901 234 567",
      diemDanhGiaTaiXe: 4.9,
      bienSo: widget.tenLoaiXe.toLowerCase().contains("máy")
          ? "59X1-234.56"
          : "51A-678.90",
      hangXe: widget.tenLoaiXe.toLowerCase().contains("máy")
          ? "Honda Wave"
          : "Toyota Vios",
      mauXe: "Đen",
      loaiXe: widget.tenLoaiXe,
      diaChiDon: widget.diaChiDon ?? "Vị trí đón hiện tại",
      diaChiDen: widget.diaChiDen ?? "Điểm đến đã chọn",
      diemDon: widget.diemDon,
      diemDen: widget.diemDen,
      khoangCachKm: widget.khoangCachKm,
      tongTien: widget.tongTien,
      phuongThucThanhToan: methods[selected].ten,
      etaPhut: 5,
    );
  }

  Future<void> _confirmPayment() async {
    setState(() => isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => isProcessing = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text("Thanh toán thành công"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Bạn đã thanh toán ${_formatVND(widget.tongTien)} bằng ${methods[selected].ten}."),
            const SizedBox(height: 6),
            Text(
              "Mã giao dịch: #TX${DateTime.now().millisecondsSinceEpoch}",
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            const Text(
              "Hệ thống đang tìm tài xế cho bạn…",
              style: TextStyle(
                  fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // đóng dialog

              // Lưu chuyến vào store và mở màn thông tin tài xế
              final trip = _createTrip();
              ActiveTripStore.startTrip(trip);

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const PassengerTripScreen()),
                (r) => false,
              );
            },
            child: const Text("Xem tài xế"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Thông tin chuyến
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple,
                  Colors.deepPurple.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tổng thanh toán",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatVND(widget.tongTien),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.directions_car,
                        color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      widget.tenLoaiXe,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Danh sách phương thức
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Chọn phương thức thanh toán",
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: methods.length,
              itemBuilder: (_, i) {
                final m = methods[i];
                final isSel = i == selected;
                return GestureDetector(
                  onTap: () => setState(() => selected = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSel ? m.color.withValues(alpha: 0.1) : Colors.white,
                      border: Border.all(
                          color: isSel ? m.color : Colors.grey.shade300,
                          width: isSel ? 2 : 1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: m.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(m.icon, color: m.color, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.ten,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m.moTa,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Radio<int>(
                          value: i,
                          groupValue: selected,
                          activeColor: m.color,
                          onChanged: (v) =>
                              setState(() => selected = v ?? 0),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Nút xác nhận
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, -2)),
              ],
            ),
            child: ElevatedButton(
              onPressed: isProcessing ? null : _confirmPayment,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      "Xác nhận thanh toán (${_formatVND(widget.tongTien)})",
                      style: const TextStyle(fontSize: 15),
                    ),
            ),
          )
        ],
      ),
    );
  }
}
