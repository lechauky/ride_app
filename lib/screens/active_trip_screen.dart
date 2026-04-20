import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'rating_screen.dart';
import 'driver_home_screen.dart';

/// Thông tin một chuyến đi đang thực hiện
class TripRequest {
  final String maChuyenDi;
  final String tenKhach;
  final String soDienThoai;
  final double diemDanhGia;
  final String diaChiDon;
  final String diaChiDen;
  final LatLng diemDon;
  final LatLng diemDen;
  final double khoangCachKm;
  final int gia;
  final String loaiXe;
  final String phuongThucThanhToan;

  TripRequest({
    required this.maChuyenDi,
    required this.tenKhach,
    required this.soDienThoai,
    required this.diemDanhGia,
    required this.diaChiDon,
    required this.diaChiDen,
    required this.diemDon,
    required this.diemDen,
    required this.khoangCachKm,
    required this.gia,
    required this.loaiXe,
    required this.phuongThucThanhToan,
  });
}

class ActiveTripScreen extends StatefulWidget {
  final TripRequest trip;
  const ActiveTripScreen({super.key, required this.trip});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  GoogleMapController? mapController;

  /// 0 = đang đến đón, 1 = đã đón khách, 2 = hoàn thành
  int trangThai = 0;

  String _formatVND(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return "${buf.toString()}₫";
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId("pickup"),
        position: widget.trip.diemDon,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: "Điểm đón",
          snippet: widget.trip.diaChiDon,
        ),
      ),
      Marker(
        markerId: const MarkerId("destination"),
        position: widget.trip.diemDen,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: "Điểm đến",
          snippet: widget.trip.diaChiDen,
        ),
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    return {
      Polyline(
        polylineId: const PolylineId("route"),
        color: Colors.deepPurple,
        width: 4,
        points: [widget.trip.diemDon, widget.trip.diemDen],
      ),
    };
  }

  LatLng _midpoint() {
    return LatLng(
      (widget.trip.diemDon.latitude + widget.trip.diemDen.latitude) / 2,
      (widget.trip.diemDon.longitude + widget.trip.diemDen.longitude) / 2,
    );
  }

  void _onAction() {
    if (trangThai == 0) {
      setState(() => trangThai = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã đón khách – bắt đầu chuyến đi")),
      );
    } else if (trangThai == 1) {
      // Hoàn thành chuyến → mời tài xế đánh giá khách
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: const [
              Icon(Icons.flag, color: Colors.green, size: 26),
              SizedBox(width: 8),
              Text("Hoàn thành chuyến"),
            ],
          ),
          content: Text(
              "Chuyến #${widget.trip.maChuyenDi} đã hoàn tất.\nTổng thu: ${_formatVND(widget.trip.gia)}\nPhương thức: ${widget.trip.phuongThucThanhToan}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // đóng dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DriverHomeScreen()),
                  (r) => false,
                );
              },
              child: const Text("Về trang chủ"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RatingScreen()),
                  (r) => false,
                );
              },
              child: const Text("Đánh giá khách"),
            ),
          ],
        ),
      );
    }
  }

  String _actionLabel() {
    switch (trangThai) {
      case 0:
        return "Đã đón khách";
      case 1:
        return "Hoàn thành chuyến";
      default:
        return "Hoàn thành";
    }
  }

  String _statusLabel() {
    switch (trangThai) {
      case 0:
        return "Đang đến đón khách";
      case 1:
        return "Đang chở khách";
      default:
        return "Hoàn thành";
    }
  }

  Color _statusColor() {
    switch (trangThai) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chuyến đang chạy"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Trạng thái
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: _statusColor().withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car, color: _statusColor()),
                const SizedBox(width: 8),
                Text(
                  _statusLabel(),
                  style: TextStyle(
                      color: _statusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
          ),

          // Bản đồ
          SizedBox(
            height: 280,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _midpoint(),
                zoom: 13,
              ),
              onMapCreated: (c) => mapController = c,
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),

          // Thông tin chuyến + khách
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card khách hàng
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.deepPurple,
                          child: Icon(Icons.person,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(t.tenKhach,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 14),
                                  Text(" ${t.diemDanhGia}",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.phone,
                                      size: 12, color: Colors.black54),
                                  Text(" ${t.soDienThoai}",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Gọi ${t.tenKhach} – ${t.soDienThoai}")),
                            );
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Mở khung chat")),
                            );
                          },
                          icon: const Icon(Icons.message,
                              color: Colors.blue),
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.blue
                                  .withValues(alpha: 0.1)),
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
                      border:
                          Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        _diaChiRow(Icons.my_location, Colors.green,
                            "Điểm đón", t.diaChiDon),
                        const Divider(),
                        _diaChiRow(Icons.location_on, Colors.red,
                            "Điểm đến", t.diaChiDen),
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
                        _infoRow("Loại xe", t.loaiXe),
                        const SizedBox(height: 6),
                        _infoRow("Khoảng cách",
                            "${t.khoangCachKm} km"),
                        const SizedBox(height: 6),
                        _infoRow("Phương thức",
                            t.phuongThucThanhToan),
                        const Divider(),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Tổng cước",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(_formatVND(t.gia),
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
                ],
              ),
            ),
          ),

          // Footer action
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
              onPressed: _onAction,
              icon: Icon(trangThai == 0
                  ? Icons.person_pin_circle
                  : Icons.flag),
              label: Text(_actionLabel(),
                  style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor:
                    trangThai == 0 ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
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
