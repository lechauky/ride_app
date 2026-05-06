import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import 'rating_screen.dart';
import 'driver_home_screen.dart';

/// Thông tin một chuyến đi đang thực hiện
class TripRequest {
  final String maChuyenDi;
  final String thanhPho;
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
    required this.thanhPho,
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

  factory TripRequest.fromJson(Map<String, dynamic> json) {
    final city = _readString(json, 'thanh_pho', fallback: 'HCM');
    final pickupLat =
        _readDouble(json, 'vi_do_diem_don') ??
        (city == 'HN' ? 21.028511 : 10.762622);
    final pickupLon =
        _readDouble(json, 'kinh_do_diem_don') ??
        (city == 'HN' ? 105.854165 : 106.660172);
    final destLat = _readDouble(json, 'vi_do_diem_den') ?? pickupLat;
    final destLon = _readDouble(json, 'kinh_do_diem_den') ?? pickupLon;

    return TripRequest(
      maChuyenDi: _readString(
        json,
        'ma_chuyen_di',
        fallback: _readString(json, 'id'),
      ),
      thanhPho: city,
      tenKhach: _readString(json, 'ten_khach', fallback: 'Khách hàng'),
      soDienThoai: _readString(json, 'so_dien_thoai', fallback: 'Chưa có SĐT'),
      diemDanhGia: _readDouble(json, 'diem_danh_gia_khach') ?? 5,
      diaChiDon: _readString(
        json,
        'dia_chi_diem_don',
        fallback: 'Vị trí đón hiện tại',
      ),
      diaChiDen: _readString(
        json,
        'dia_chi_diem_den',
        fallback: 'Điểm đến đã chọn',
      ),
      diemDon: LatLng(pickupLat, pickupLon),
      diemDen: LatLng(destLat, destLon),
      khoangCachKm: _readDouble(json, 'khoang_cach_km') ?? 1,
      gia: _readInt(json, 'so_tien') ?? 0,
      loaiXe: _rideTypeLabel(
        _readString(json, 'ma_loai_dich_vu'),
        _readString(json, 'ten_loai_dich_vu'),
      ),
      phuongThucThanhToan: _paymentLabel(
        _readString(json, 'phuong_thuc', fallback: 'tien_mat'),
      ),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) {
    final value = json[key];
    if (value == null) return fallback;
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }

  static double? _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  static String _rideTypeLabel(String id, String label) {
    if (label.isNotEmpty) return label;
    if (id == 'car7') return 'Ô tô 7 chỗ';
    if (id == 'car4') return 'Ô tô 4 chỗ';
    return 'Xe máy';
  }

  static String _paymentLabel(String id) {
    if (id == 'vi_dien_tu') return 'Ví điện tử';
    if (id == 'the_ngan_hang') return 'Thẻ ngân hàng';
    return 'Tiền mặt';
  }
}

class ActiveTripScreen extends StatefulWidget {
  final TripRequest trip;
  const ActiveTripScreen({super.key, required this.trip});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  final MapController mapController = MapController();

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

  List<Marker> _buildMarkers() {
    return [
      Marker(
        point: widget.trip.diemDon,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.green, size: 40),
      ),
      Marker(
        point: widget.trip.diemDen,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
    ];
  }

  List<Polyline> _buildPolylines() {
    return [
      Polyline(
        color: Colors.deepPurple,
        strokeWidth: 4,
        points: [widget.trip.diemDon, widget.trip.diemDen],
      ),
    ];
  }

  LatLng _midpoint() {
    return LatLng(
      (widget.trip.diemDon.latitude + widget.trip.diemDen.latitude) / 2,
      (widget.trip.diemDon.longitude + widget.trip.diemDen.longitude) / 2,
    );
  }

  Future<void> _onAction() async {
    if (trangThai == 0) {
      setState(() => trangThai = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã đón khách – bắt đầu chuyến đi")),
      );
    } else if (trangThai == 1) {
      final res = await ApiService.post(
        'trips/${widget.trip.maChuyenDi}/complete',
        widget.trip.thanhPho,
        {'thanh_pho': widget.trip.thanhPho},
      );

      if (!mounted) return;

      if (res["data"] == null || res["data"]["success"] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res["data"]?["message"] ?? "Lỗi hoàn thành chuyến"),
          ),
        );
        return;
      }

      // Hoàn thành chuyến → mời tài xế đánh giá khách
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: const [
              Icon(Icons.flag, color: Colors.green, size: 26),
              SizedBox(width: 8),
              Text("Hoàn thành chuyến"),
            ],
          ),
          content: Text(
            "Chuyến #${widget.trip.maChuyenDi} đã hoàn tất.\nTổng thu: ${_formatVND(widget.trip.gia)}\nPhương thức: ${widget.trip.phuongThucThanhToan}",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // đóng dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
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
                  MaterialPageRoute(
                    builder: (_) => RatingScreen(
                      target: RatingTarget.passenger,
                      targetName: widget.trip.tenKhach,
                      targetSubInfo:
                          "${widget.trip.soDienThoai} • Chuyến #${widget.trip.maChuyenDi}",
                    ),
                  ),
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
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Bản đồ
          SizedBox(
            height: 280,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(initialCenter: _midpoint(), initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ride_app',
                ),
                PolylineLayer(polylines: _buildPolylines()),
                MarkerLayer(markers: _buildMarkers()),
              ],
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
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.deepPurple,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.tenKhach,
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
                                    " ${t.diemDanhGia}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.phone,
                                    size: 12,
                                    color: Colors.black54,
                                  ),
                                  Text(
                                    " ${t.soDienThoai}",
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Gọi ${t.tenKhach} – ${t.soDienThoai}",
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.call, color: Colors.green),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Mở khung chat")),
                            );
                          },
                          icon: const Icon(Icons.message, color: Colors.blue),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          ),
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
                          t.diaChiDon,
                        ),
                        const Divider(),
                        _diaChiRow(
                          Icons.location_on,
                          Colors.red,
                          "Điểm đến",
                          t.diaChiDen,
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
                        _infoRow("Loại xe", t.loaiXe),
                        const SizedBox(height: 6),
                        _infoRow("Khoảng cách", "${t.khoangCachKm} km"),
                        const SizedBox(height: 6),
                        _infoRow("Phương thức", t.phuongThucThanhToan),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Tổng cước",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _formatVND(t.gia),
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
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _onAction,
              icon: Icon(trangThai == 0 ? Icons.person_pin_circle : Icons.flag),
              label: Text(_actionLabel(), style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: trangThai == 0 ? Colors.orange : Colors.green,
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
