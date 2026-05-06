import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/auth_store.dart';
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
  bool isLoadingRequest = false;
  bool isUpdatingRequest = false;

  @override
  void initState() {
    super.initState();
    _loadIncomingRequest();
    _requestTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (dangRanh && incomingRequest == null && !isLoadingRequest) {
        _loadIncomingRequest();
      }
    });
  }

  @override
  void dispose() {
    _requestTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  LatLng _defaultPositionForCity(String city) {
    return city == "HN"
        ? const LatLng(21.028511, 105.854165)
        : const LatLng(10.762622, 106.660172);
  }

  Future<LatLng?> _getDriverPosition(String city) async {
    if (kIsWeb) return _defaultPositionForCity(city);

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _defaultPositionForCity(city);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return _defaultPositionForCity(city);
    }
  }

  Future<void> _loadIncomingRequest() async {
    if (!dangRanh || isLoadingRequest) return;

    final city = AuthStore.currentUser.value?.thanhPho ?? "HCM";
    setState(() => isLoadingRequest = true);

    try {
      final position = await _getDriverPosition(city);
      final query = Uri(
        queryParameters: {
          "thanh_pho": city,
          "limit": "1",
          if (position != null) "latitude": position.latitude.toString(),
          if (position != null) "longitude": position.longitude.toString(),
        },
      ).query;

      final res = await ApiService.get('trips/pending/nearest?$query', city);
      final data = res["data"];
      final items = data?["data"];

      if (!mounted) return;

      if (data?["success"] == true && items is List && items.isNotEmpty) {
        _showIncomingRequest(
          TripRequest.fromJson(Map<String, dynamic>.from(items.first as Map)),
        );
      }
    } catch (_) {
      // Polling silently retries so the driver screen stays usable offline.
    } finally {
      if (mounted) setState(() => isLoadingRequest = false);
    }
  }

  void _showIncomingRequest(TripRequest request) {
    setState(() {
      incomingRequest = request;
      countdown = 15;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => countdown--);
      if (countdown <= 0) {
        timer.cancel();
        _rejectRequest(auto: true);
      }
    });
  }

  Future<void> _acceptRequest() async {
    final req = incomingRequest;
    if (req == null) return;

    _countdownTimer?.cancel();
    setState(() => isUpdatingRequest = true);

    final res = await ApiService.post(
      'trips/${req.maChuyenDi}/accept',
      req.thanhPho,
      {'thanh_pho': req.thanhPho},
    );

    if (!mounted) return;
    setState(() => isUpdatingRequest = false);

    if (res["data"] == null || res["data"]["success"] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["data"]?["message"] ?? "Lỗi nhận chuyến")),
      );
      _loadIncomingRequest();
      return;
    }

    setState(() => incomingRequest = null);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActiveTripScreen(trip: req)),
    ).then((_) {
      if (mounted && dangRanh) _loadIncomingRequest();
    });
  }

  Future<void> _rejectRequest({bool auto = false}) async {
    final req = incomingRequest;
    _countdownTimer?.cancel();
    if (req == null) return;
    setState(() => incomingRequest = null);

    await ApiService.post('trips/${req.maChuyenDi}/reject', req.thanhPho, {
      'thanh_pho': req.thanhPho,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auto
                ? "Đã hết thời gian — chuyến được giao cho tài xế khác"
                : "Bạn đã từ chối chuyến",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (dangRanh) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && dangRanh && incomingRequest == null) {
          _loadIncomingRequest();
        }
      });
    }
  }

  Future<void> _onToggleRanh(bool v) async {
    final previous = dangRanh;
    setState(() => dangRanh = v);
    final city = AuthStore.currentUser.value?.thanhPho ?? "HCM";
    final res = await ApiService.put("drivers/availability", city, {
      "is_available": v,
      "thanh_pho": city,
    });

    if (!mounted) return;
    if (res["data"] == null || res["data"]["success"] != true) {
      setState(() => dangRanh = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res["data"]?["message"] ?? "Lỗi cập nhật trạng thái tài xế",
          ),
        ),
      );
      return;
    }

    if (v) {
      _loadIncomingRequest();
    } else {
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
    final user = AuthStore.currentUser.value;
    final tenTaiXe = user?.hoTen ?? "Tài xế";

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
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthStore.logout();
              if (!mounted) return;
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
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade400],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.drive_eta,
                      color: Colors.deepPurple,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Xin chào,",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          "Tài xế $tenTaiXe",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "⭐ 4.9 • 234 chuyến",
                          style: TextStyle(color: Colors.white70),
                        ),
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
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: SwitchListTile(
                value: dangRanh,
                onChanged: _onToggleRanh,
                title: Text(
                  dangRanh ? "Đang sẵn sàng nhận chuyến" : "Tạm nghỉ",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  dangRanh
                      ? "Hệ thống có thể giao chuyến cho bạn"
                      : "Bạn sẽ không nhận được chuyến mới",
                ),
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
            const Text(
              "Chức năng",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
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
                        builder: (_) => const VehicleInfoScreen(),
                      ),
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
                        builder: (_) => const NotificationsScreen(),
                      ),
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
                        builder: (_) =>
                            const RatingScreen(target: RatingTarget.passenger),
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
                        content: Text("Mở lịch sử chuyến của tài xế"),
                      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "CUỐC XE MỚI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // đếm ngược
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: countdown <= 5
                      ? Colors.red.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 14,
                      color: countdown <= 5 ? Colors.red : Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${countdown}s",
                      style: TextStyle(
                        color: countdown <= 5 ? Colors.red : Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
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
                child: Icon(Icons.person, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.tenKhach,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        Text(
                          " ${r.diemDanhGia}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.straighten,
                          size: 12,
                          color: Colors.black54,
                        ),
                        Text(
                          " ${r.khoangCachKm} km • ${r.loaiXe}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
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
                  Text(
                    r.phuongThucThanhToan,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 22),

          // Địa chỉ đón / đến
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.my_location, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.diaChiDon, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Icon(Icons.more_vert, size: 14, color: Colors.black26),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.diaChiDen, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hành động
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUpdatingRequest ? null : () => _rejectRequest(),
                  icon: const Icon(Icons.close),
                  label: const Text("Từ chối"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isUpdatingRequest ? null : _acceptRequest,
                  icon: const Icon(Icons.check),
                  label: const Text("Nhận cuốc"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
              strokeWidth: 2.4,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Đang chờ cuốc xe…",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  "Hệ thống sẽ gửi cuốc gần bạn nhất",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isLoadingRequest ? null : _loadIncomingRequest,
            child: const Text("Làm mới"),
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

  Widget _menu({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
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
              offset: const Offset(0, 2),
            ),
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
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
