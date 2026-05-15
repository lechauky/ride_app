import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/active_trip_store.dart';
import 'home_screen.dart';
import 'rating_screen.dart';

class PassengerTripScreen extends StatefulWidget {
  const PassengerTripScreen({super.key});

  @override
  State<PassengerTripScreen> createState() => _PassengerTripScreenState();
}

class _PassengerTripScreenState extends State<PassengerTripScreen> {
  final MapController mapController = MapController();
  Timer? _detailTimer;
  bool _isLoadingDetails = false;
  bool _ratingPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTripDetails());
    _detailTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadTripDetails(),
    );
  }

  @override
  void dispose() {
    _detailTimer?.cancel();
    super.dispose();
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

  IconData _vehicleIcon(String loaiXe) {
    final value = loaiXe.toLowerCase();
    if (value.contains("máy")) return Icons.two_wheeler;
    if (value.contains("7")) return Icons.airport_shuttle;
    return Icons.directions_car;
  }

  List<Marker> _markers(PassengerTripInfo t) {
    final s = <Marker>[];
    if (t.diemDon != null) {
      s.add(
        Marker(
          point: t.diemDon!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
      );
    }
    if (t.diemDen != null) {
      s.add(
        Marker(
          point: t.diemDen!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }
    return s;
  }

  List<Polyline> _polylines(PassengerTripInfo t) {
    if (t.diemDon == null || t.diemDen == null) return [];
    return [
      Polyline(
        color: Colors.deepPurple,
        strokeWidth: 4,
        points: [t.diemDon!, t.diemDen!],
      ),
    ];
  }

  LatLng _initialCamera(PassengerTripInfo t) {
    if (t.diemDon != null && t.diemDen != null) {
      return LatLng(
        (t.diemDon!.latitude + t.diemDen!.latitude) / 2,
        (t.diemDon!.longitude + t.diemDen!.longitude) / 2,
      );
    }
    return t.diemDon ?? t.diemDen ?? const LatLng(10.762622, 106.660172);
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (r) => false,
    );
  }

  Future<void> _loadTripDetails() async {
    final trip = ActiveTripStore.currentTrip.value;
    if (trip == null || _isLoadingDetails) return;

    _isLoadingDetails = true;
    try {
      final updated = await ActiveTripStore.refreshCurrentTrip();
      if (!mounted || updated == null) return;
      if (ActiveTripStore.shouldPromptDriverRating(updated)) {
        _showCompletedRatingPrompt(updated);
      }
    } finally {
      _isLoadingDetails = false;
    }
  }

  void _openDriverRating(PassengerTripInfo t) {
    ActiveTripStore.endTrip();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => RatingScreen(
          target: RatingTarget.driver,
          tripId: t.maChuyenDi,
          thanhPho: t.thanhPho,
          targetName: t.tenTaiXe,
          targetSubInfo: "${t.hangXe} • ${t.bienSo}",
        ),
      ),
      (r) => false,
    );
  }

  void _showCompletedRatingPrompt(PassengerTripInfo t) {
    if (_ratingPromptShown || !mounted) return;
    _ratingPromptShown = true;
    _detailTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 26),
            SizedBox(width: 8),
            Text("Chuyến đã hoàn thành"),
          ],
        ),
        content: Text(
          "Tài xế ${t.tenTaiXe} đã hoàn thành chuyến đi.\nBạn có thể đánh giá tài xế để lưu phản hồi vào hệ thống.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ActiveTripStore.endTrip();
              _goHome();
            },
            child: const Text("Bỏ qua"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _openDriverRating(t);
            },
            child: const Text("Đánh giá tài xế"),
          ),
        ],
      ),
    );
  }

  void _cancelTrip() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Huỷ chuyến?"),
        content: const Text(
          "Bạn có chắc muốn huỷ chuyến này không? Có thể bị tính phí huỷ chuyến.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Không"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ActiveTripStore.endTrip();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Đã huỷ chuyến")));
              _goHome();
            },
            child: const Text("Huỷ chuyến"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PassengerTripInfo?>(
      valueListenable: ActiveTripStore.currentTrip,
      builder: (context, trip, _) {
        if (trip == null) {
          // Trip vừa bị clear ngoài luồng — quay về home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _goHome();
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Chuyến đi của bạn"),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.home_outlined),
                tooltip: "Về trang chủ",
                onPressed: _goHome,
              ),
            ],
          ),
          body: Column(
            children: [
              // Banner trạng thái chuyến
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: trip.hasDriver
                        ? [Colors.green.shade600, Colors.green.shade400]
                        : [Colors.deepPurple, Colors.deepPurple.shade300],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      trip.hasDriver ? Icons.check_circle : Icons.search,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.hasDriver
                                ? "Tài xế đã nhận cuốc"
                                : "Đang tìm tài xế",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            trip.hasDriver
                                ? "Sẽ tới điểm đón sau ~ ${trip.etaPhut} phút"
                                : "Chuyến đã được lưu, hệ thống đang chờ tài xế trong ${trip.thanhPho}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bản đồ
              SizedBox(
                height: 240,
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: _initialCamera(trip),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ride_app',
                    ),
                    PolylineLayer(polylines: _polylines(trip)),
                    MarkerLayer(markers: _markers(trip)),
                  ],
                ),
              ),

              // Cuộn
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card tài xế
                      if (!trip.hasDriver)
                        _buildWaitingDriverCard(trip)
                      else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.deepPurple,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trip.tenTaiXe,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 14,
                                            ),
                                            Text(
                                              " ${trip.diemDanhGiaTaiXe}",
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
                                  IconButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("Gọi ${trip.sdtTaiXe}"),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.green,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Tính năng chat không dùng trong demo này",
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.message,
                                      color: Colors.blue,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.blue.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 22),
                              Row(
                                children: [
                                  Icon(
                                    _vehicleIcon(trip.loaiXe),
                                    color: Colors.deepPurple,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${trip.hangXe} • ${trip.mauXe}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          trip.bienSo,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      trip.loaiXe,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Card lộ trình
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            _diaChiRow(
                              Icons.my_location,
                              Colors.green,
                              "Điểm đón",
                              trip.diaChiDon,
                            ),
                            const Divider(),
                            _diaChiRow(
                              Icons.location_on,
                              Colors.red,
                              "Điểm đến",
                              trip.diaChiDen,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Card thanh toán
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            _infoRow("Mã chuyến", "#${trip.maChuyenDi}"),
                            const SizedBox(height: 6),
                            _infoRow("Khoảng cách", "${trip.khoangCachKm} km"),
                            const SizedBox(height: 6),
                            _infoRow("Phương thức", trip.phuongThucThanhToan),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Tổng cước",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  _formatVND(trip.tongTien),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Hành động
                      TextButton.icon(
                        onPressed: _cancelTrip,
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text(
                          "Huỷ chuyến",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer: nút quay về trang chủ (vẫn giữ chuyến)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _goHome,
                  icon: const Icon(Icons.home),
                  label: const Text("Về trang chủ"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaitingDriverCard(PassengerTripInfo trip) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Đang tìm tài xế gần điểm đón",
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Khu vực ${trip.thanhPho}. Màn hình sẽ tự cập nhật khi tài xế nhận chuyến.",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Tải lại trạng thái chuyến",
            onPressed: _loadTripDetails,
            icon: const Icon(Icons.refresh, color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }

  Widget _diaChiRow(IconData icon, Color color, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
