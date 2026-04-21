import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'vehicle_info_screen.dart';
import 'notifications_screen.dart';
import 'rating_screen.dart';
import 'login_screen.dart';
import 'active_trip_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool dangRanh = true;
  TripRequest? incomingRequest;
  Timer? _requestTimer;
  Timer? _countdownTimer;
  int countdown = 15; // 15 giây để quyết định nhận / từ chối

  @override
  void initState() {
    super.initState();
    _scheduleNewRequest();
  }

  @override
  void dispose() {
    _requestTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Giả lập có cuốc xe mới sau vài giây nếu tài xế đang rảnh
  void _scheduleNewRequest() {
    _requestTimer?.cancel();
    _requestTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (dangRanh && incomingRequest == null) {
        _showIncomingRequest();
      }
    });
  }

  void _showIncomingRequest() {
    setState(() {
      incomingRequest = _mockRequest();
      countdown = 15;
    });
    _countdownTimer?.cancel();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => countdown--);
      if (countdown <= 0) {
        timer.cancel();
        _rejectRequest(auto: true);
      }
    });
  }

  TripRequest _mockRequest() {
    // Một cuốc xe giả lập trong khu vực Quận 1 → Quận 7 (HCM)
    return TripRequest(
      maChuyenDi: "${DateTime.now().millisecondsSinceEpoch % 100000}",
      tenKhach: "Trần Thị B",
      soDienThoai: "0987 654 321",
      diemDanhGia: 4.8,
      diaChiDon: "12 Lê Lợi, Quận 1, TP.HCM",
      diaChiDen: "Crescent Mall, Quận 7, TP.HCM",
      diemDon: const LatLng(10.773080, 106.703610),
      diemDen: const LatLng(10.729188, 106.719329),
      khoangCachKm: 7.2,
      gia: 104000,
      loaiXe: "Xe máy",
      phuongThucThanhToan: "Tiền mặt",
    );
  }

  void _acceptRequest() {
    final req = incomingRequest;
    _countdownTimer?.cancel();
    setState(() => incomingRequest = null);
    if (req == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActiveTripScreen(trip: req)),
    ).then((_) {
      // Khi quay lại home → tiếp tục lịch cuốc mới
      if (mounted && dangRanh) _scheduleNewRequest();
    });
  }

  void _rejectRequest({bool auto = false}) {
    _countdownTimer?.cancel();
    if (incomingRequest == null) return;
    setState(() => incomingRequest = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auto
              ? "Đã hết thời gian — chuyến được giao cho tài xế khác"
              : "Bạn đã từ chối chuyến"),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Sau khi từ chối, sau 5s lại có cuốc khác
    if (dangRanh) _scheduleNewRequest();
  }

  void _onToggleRanh(bool v) {
    setState(() => dangRanh = v);
    if (v) {
      _scheduleNewRequest();
    } else {
      _requestTimer?.cancel();
      _countdownTimer?.cancel();
      setState(() => incomingRequest = null);
    }
  }

  String _formatVND(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return "${buf.toString()}₫";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tài xế"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card profile
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.deepPurple,
                  Colors.deepPurple.shade400,
                ]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.drive_eta,
                        color: Colors.deepPurple, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Xin chào,",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        Text("Tài xế Nguyễn Văn A",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("⭐ 4.9 • 234 chuyến",
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Switch trạng thái
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: SwitchListTile(
                value: dangRanh,
                onChanged: _onToggleRanh,
                title: Text(
                  dangRanh ? "Đang sẵn sàng nhận chuyến" : "Tạm nghỉ",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(dangRanh
                    ? "Hệ thống có thể giao chuyến cho bạn"
                    : "Bạn sẽ không nhận được chuyến mới"),
                secondary: Icon(
                  dangRanh ? Icons.online_prediction : Icons.pause_circle,
                  color: dangRanh ? Colors.green : Colors.grey,
                  size: 32,
                ),
                activeThumbColor: Colors.green,
              ),
            ),

            // Card cuốc xe mới hoặc trạng thái chờ
            const SizedBox(height: 16),
            if (incomingRequest != null)
              _buildIncomingRequestCard(incomingRequest!)
            else if (dangRanh)
              _buildSearchingCard()
            else
              _buildOfflineCard(),

            const SizedBox(height: 16),
            const Text("Chức năng",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _menu(
                  icon: Icons.directions_car,
                  label: "Thông tin xe",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VehicleInfoScreen()),
                    );
                  },
                ),
                _menu(
                  icon: Icons.notifications,
                  label: "Thông báo",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                _menu(
                  icon: Icons.star,
                  label: "Đánh giá khách",
                  color: Colors.amber,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RatingScreen(
                          target: RatingTarget.passenger,
                        ),
                      ),
                    );
                  },
                ),
                _menu(
                  icon: Icons.history,
                  label: "Lịch sử",
                  color: Colors.green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Mở lịch sử chuyến của tài xế")),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- WIDGETS ----------

  Widget _buildIncomingRequestCard(TripRequest r) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.deepPurple, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_active,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text("CUỐC XE MỚI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
              const Spacer(),
              // đếm ngược
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: countdown <= 5
                      ? Colors.red.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer,
                        size: 14,
                        color: countdown <= 5
                            ? Colors.red
                            : Colors.black54),
                    const SizedBox(width: 4),
                    Text("${countdown}s",
                        style: TextStyle(
                          color: countdown <= 5
                              ? Colors.red
                              : Colors.black54,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Khách + giá
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.deepPurple,
                child:
                    Icon(Icons.person, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.tenKhach,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 12, color: Colors.amber),
                        Text(" ${r.diemDanhGia}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                        const SizedBox(width: 8),
                        const Icon(Icons.straighten,
                            size: 12, color: Colors.black54),
                        Text(" ${r.khoangCachKm} km • ${r.loaiXe}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatVND(r.gia),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  Text(r.phuongThucThanhToan,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black54)),
                ],
              ),
            ],
          ),
          const Divider(height: 22),

          // Địa chỉ đón / đến
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.my_location,
                  color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.diaChiDon,
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Icon(Icons.more_vert,
                size: 14, color: Colors.black26),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on,
                  color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.diaChiDen,
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hành động
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectRequest(),
                  icon: const Icon(Icons.close),
                  label: const Text("Từ chối"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _acceptRequest,
                  icon: const Icon(Icons.check),
                  label: const Text("Nhận cuốc"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: Colors.green),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Đang chờ cuốc xe…",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                Text("Hệ thống sẽ gửi cuốc gần bạn nhất",
                    style: TextStyle(
                        fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          // nút giả lập (test): tạo ngay 1 cuốc
          TextButton(
            onPressed: () => _showIncomingRequest(),
            child: const Text("Test cuốc"),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: const [
          Icon(Icons.pause_circle, color: Colors.grey, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Bạn đang tạm nghỉ. Bật trạng thái sẵn sàng để bắt đầu nhận chuyến.",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
