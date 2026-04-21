import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/active_trip_store.dart';
import 'home_screen.dart';
import 'rating_screen.dart';

class PassengerTripScreen extends StatefulWidget {
  const PassengerTripScreen({super.key});

  @override
  State<PassengerTripScreen> createState() => _PassengerTripScreenState();
}

class _PassengerTripScreenState extends State<PassengerTripScreen> {
  GoogleMapController? mapController;

  String _formatVND(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return "${buf.toString()}₫";
  }

  Set<Marker> _markers(PassengerTripInfo t) {
    final s = <Marker>{};
    if (t.diemDon != null) {
      s.add(Marker(
        markerId: const MarkerId("pickup"),
        position: t.diemDon!,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
            title: "Điểm đón", snippet: t.diaChiDon),
      ));
    }
    if (t.diemDen != null) {
      s.add(Marker(
        markerId: const MarkerId("destination"),
        position: t.diemDen!,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
            title: "Điểm đến", snippet: t.diaChiDen),
      ));
    }
    return s;
  }

  Set<Polyline> _polylines(PassengerTripInfo t) {
    if (t.diemDon == null || t.diemDen == null) return {};
    return {
      Polyline(
        polylineId: const PolylineId("route"),
        color: Colors.deepPurple,
        width: 4,
        points: [t.diemDon!, t.diemDen!],
      ),
    };
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

  void _completeAndRate(PassengerTripInfo t) {
    // Giả lập chuyến kết thúc → cho khách đánh giá tài xế
    ActiveTripStore.endTrip();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => RatingScreen(
          target: RatingTarget.driver,
          targetName: t.tenTaiXe,
          targetSubInfo: "${t.hangXe} • ${t.bienSo}",
        ),
      ),
      (r) => false,
    );
  }

  void _cancelTrip() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Huỷ chuyến?"),
        content: const Text(
            "Bạn có chắc muốn huỷ chuyến này không? Có thể bị tính phí huỷ chuyến."),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã huỷ chuyến")),
              );
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
              // Banner: Tài xế đã nhận cuốc
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.green.shade600,
                    Colors.green.shade400,
                  ]),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tài xế đã nhận cuốc",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "Sẽ tới điểm đón sau ~ ${trip.etaPhut} phút",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
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
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialCamera(trip),
                    zoom: 13,
                  ),
                  onMapCreated: (c) => mapController = c,
                  markers: _markers(trip),
                  polylines: _polylines(trip),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
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
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.deepPurple,
                                  child: Icon(Icons.person,
                                      color: Colors.white, size: 32),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(trip.tenTaiXe,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              color: Colors.amber,
                                              size: 14),
                                          Text(
                                              " ${trip.diemDanhGiaTaiXe}",
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors
                                                      .black54)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                            content: Text(
                                                "Gọi ${trip.sdtTaiXe}")));
                                  },
                                  icon: const Icon(Icons.call,
                                      color: Colors.green),
                                  style: IconButton.styleFrom(
                                      backgroundColor: Colors.green
                                          .withValues(alpha: 0.1)),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content:
                                                Text("Mở khung chat")));
                                  },
                                  icon: const Icon(Icons.message,
                                      color: Colors.blue),
                                  style: IconButton.styleFrom(
                                      backgroundColor: Colors.blue
                                          .withValues(alpha: 0.1)),
                                ),
                              ],
                            ),
                            const Divider(height: 22),
                            Row(
                              children: [
                                Icon(
                                    trip.loaiXe.toLowerCase().contains(
                                            "máy")
                                        ? Icons.two_wheeler
                                        : Icons.directions_car,
                                    color: Colors.deepPurple,
                                    size: 28),
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
                                              fontWeight:
                                                  FontWeight.w500)),
                                      Text(
                                        trip.bienSo,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                            letterSpacing: 1.2),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    borderRadius:
                                        BorderRadius.circular(8),
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
                          border: Border.all(
                              color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            _diaChiRow(Icons.my_location, Colors.green,
                                "Điểm đón", trip.diaChiDon),
                            const Divider(),
                            _diaChiRow(Icons.location_on, Colors.red,
                                "Điểm đến", trip.diaChiDen),
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
                            _infoRow("Mã chuyến",
                                "#${trip.maChuyenDi}"),
                            const SizedBox(height: 6),
                            _infoRow("Khoảng cách",
                                "${trip.khoangCachKm} km"),
                            const SizedBox(height: 6),
                            _infoRow("Phương thức",
                                trip.phuongThucThanhToan),
                            const Divider(),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Tổng cước",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(_formatVND(trip.tongTien),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Hành động
                      OutlinedButton.icon(
                        onPressed: () => _completeAndRate(trip),
                        icon: const Icon(Icons.flag),
                        label: const Text(
                            "Đã hoàn thành chuyến (giả lập)"),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor: Colors.green,
                          side: const BorderSide(
                              color: Colors.green),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _cancelTrip,
                        icon: const Icon(Icons.cancel,
                            color: Colors.red),
                        label: const Text("Huỷ chuyến",
                            style: TextStyle(color: Colors.red)),
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
                        offset: const Offset(0, -2)),
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
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _diaChiRow(
      IconData icon, Color color, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
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
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: Colors.black54)),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
