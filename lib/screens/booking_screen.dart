import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/auth_store.dart';
import 'ride_types_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final pickup = TextEditingController();
  final destination = TextEditingController();

  bool isValid = false;
  bool _isLoadingNearbyDrivers = false;
  String? _nearbyDriversMessage;
  int _nearbyDriversRequestId = 0;
  final List<_NearbyDriver> _nearbyDrivers = [];

  // bản đồ
  final MapController mapController = MapController();
  LatLng currentPosition = LatLng(10.762622, 106.660172); // TP.HCM
  LatLng? pickupLatLng;
  LatLng? destinationLatLng;
  bool isSelectingDestination = false; // Cờ xác định đang chọn điểm nào

  @override
  void initState() {
    super.initState();
    pickup.addListener(validate);
    destination.addListener(validate);

    getCurrentLocation();
  }

  void validate() {
    setState(() {
      isValid =
          pickup.text.trim().isNotEmpty && destination.text.trim().isNotEmpty;
    });
  }

  // Tính khoảng cách (km) bằng công thức Haversine
  double _calculateDistanceKm(LatLng a, LatLng b) {
    const R = 6371.0; // bán kính Trái Đất (km)
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return R * c;
  }

  Future<void> _loadNearbyDrivers(LatLng? pickupPoint) async {
    final requestId = ++_nearbyDriversRequestId;

    if (pickupPoint == null) {
      if (!mounted) return;
      setState(() {
        _nearbyDrivers.clear();
        _nearbyDriversMessage = null;
        _isLoadingNearbyDrivers = false;
      });
      return;
    }

    final city = AuthStore.currentUser.value?.thanhPho ?? "HCM";
    setState(() {
      _isLoadingNearbyDrivers = true;
      _nearbyDriversMessage = "Đang tìm tài xế gần điểm đón...";
    });

    try {
      final res = await ApiService.post("drivers/nearest", city, {
        "latitude": pickupPoint.latitude,
        "longitude": pickupPoint.longitude,
        "thanh_pho": city,
        "max_distance": 10,
        "limit": 5,
      });

      final data = res["data"];
      final items = data is Map ? data["data"] : null;
      final drivers = items is List
          ? items
                .whereType<Map>()
                .map(
                  (item) =>
                      _NearbyDriver.fromJson(Map<String, dynamic>.from(item)),
                )
                .whereType<_NearbyDriver>()
                .toList()
          : <_NearbyDriver>[];

      if (!mounted || requestId != _nearbyDriversRequestId) return;
      setState(() {
        _nearbyDrivers
          ..clear()
          ..addAll(drivers);
        _nearbyDriversMessage = drivers.isEmpty
            ? "Không có tài xế gần điểm đón"
            : "${drivers.length} tài xế gần điểm đón";
      });
    } catch (_) {
      if (!mounted || requestId != _nearbyDriversRequestId) return;
      setState(() {
        _nearbyDrivers.clear();
        _nearbyDriversMessage = "Chưa tải được tài xế gần đây";
      });
    } finally {
      if (mounted && requestId == _nearbyDriversRequestId) {
        setState(() => _isLoadingNearbyDrivers = false);
      }
    }
  }

  Future<void> _onConfirmBooking() async {
    // Nếu user chỉ gõ địa chỉ mà chưa submit để geocode → thử geocode trước
    pickupLatLng ??= await getLatLngFromAddress(pickup.text);
    destinationLatLng ??= await getLatLngFromAddress(destination.text);

    double khoangCach = 5.0; // mặc định nếu không tính được
    if (pickupLatLng != null && destinationLatLng != null) {
      final d = _calculateDistanceKm(pickupLatLng!, destinationLatLng!);
      // Làm tròn 1 chữ số thập phân, tối thiểu 1km
      khoangCach = double.parse(d.toStringAsFixed(1));
      if (khoangCach < 1.0) khoangCach = 1.0;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Xác nhận đặt xe — khoảng cách ~ $khoangCach km 🚗"),
        duration: const Duration(seconds: 1),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideTypesScreen(
          khoangCachKm: khoangCach,
          diaChiDon: pickup.text.trim(),
          diaChiDen: destination.text.trim(),
          diemDon: pickupLatLng,
          diemDen: destinationLatLng,
        ),
      ),
    );
  }

  Future<LatLng?> getLatLngFromAddress(String address) async {
    if (kIsWeb) {
      // Geocoding không hỗ trợ tốt trên web, trả null
      return null;
    }
    try {
      List<Location> locations = await locationFromAddress(address);
      return LatLng(locations.first.latitude, locations.first.longitude);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<void> getCurrentLocation() async {
    if (kIsWeb) {
      // Trên web, dùng vị trí mặc định TP.HCM
      setState(() {
        currentPosition = LatLng(10.762622, 106.660172);
        pickupLatLng = currentPosition;
        pickup.text = "10.762622, 106.660172";
      });
      mapController.move(currentPosition, 16);
      _loadNearbyDrivers(currentPosition);
      return;
    }

    // xin quyền
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint("Không có quyền GPS");
      return;
    }

    // lấy vị trí
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );

    LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      currentPosition = currentLatLng;
      pickupLatLng = currentLatLng;
      pickup.text = "${position.latitude}, ${position.longitude}";
    });

    // di chuyển map
    mapController.move(currentLatLng, 16);
    _loadNearbyDrivers(currentLatLng);
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (pickupLatLng != null) {
      markers.add(
        Marker(
          point: pickupLatLng!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
      );
    } else {
      markers.add(
        Marker(
          point: currentPosition,
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
        ),
      );
    }

    if (destinationLatLng != null) {
      markers.add(
        Marker(
          point: destinationLatLng!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    for (final driver in _nearbyDrivers) {
      markers.add(
        Marker(
          point: driver.position,
          width: 44,
          height: 44,
          child: Tooltip(
            message: driver.tooltip,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(driver.icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildNearbyDriversStatus() {
    final message = _nearbyDriversMessage ?? "Chọn điểm đón để xem tài xế gần";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          if (_isLoadingNearbyDrivers)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _nearbyDrivers.isEmpty ? Icons.info_outline : Icons.local_taxi,
              color: Colors.deepPurple,
              size: 20,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: "Tải lại tài xế gần",
            onPressed: _isLoadingNearbyDrivers
                ? null
                : () => _loadNearbyDrivers(pickupLatLng),
            icon: const Icon(Icons.refresh, size: 20),
            color: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đặt xe")),
      body: Column(
        children: [
          // MAP
          SizedBox(
            height: 250,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentPosition,
                initialZoom: 14,
                onTap: (tapPosition, point) {
                  final isDestinationTap = isSelectingDestination;
                  setState(() {
                    if (isDestinationTap) {
                      destinationLatLng = point;
                      destination.text =
                          "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
                    } else {
                      pickupLatLng = point;
                      pickup.text =
                          "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
                    }
                  });
                  if (!isDestinationTap) {
                    _loadNearbyDrivers(point);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ride_app',
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: getCurrentLocation,
                    icon: Icon(Icons.my_location),
                    label: Text("Lấy vị trí hiện tại"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildNearbyDriversStatus(),
                  SizedBox(height: 15),

                  _buildInput(
                    "Điểm đón (Nhấn vào đây rồi chạm bản đồ)",
                    pickup,
                    false,
                  ),
                  SizedBox(height: 15),
                  _buildInput(
                    "Điểm đến (Nhấn vào đây rồi chạm bản đồ)",
                    destination,
                    true,
                  ),
                  SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: isValid ? _onConfirmBooking : null,
                    child: Text("Xác nhận đặt xe"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    bool isDest,
  ) {
    final isActive = isSelectingDestination == isDest;
    return TextField(
      controller: controller,
      onTap: () {
        setState(() {
          isSelectingDestination = isDest;
        });
      },
      onSubmitted: (value) async {
        LatLng? pos = await getLatLngFromAddress(value);

        if (pos != null) {
          final isPickup = controller == pickup;
          setState(() {
            if (isPickup) {
              pickupLatLng = pos;
            } else {
              destinationLatLng = pos;
            }
          });

          // Di chuyển camera
          mapController.move(pos, 16);
          if (isPickup) {
            _loadNearbyDrivers(pos);
          }
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isActive ? Colors.deepPurple : Colors.grey,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        prefixIcon: Icon(
          isDest ? Icons.location_on : Icons.my_location,
          color: isActive ? (isDest ? Colors.red : Colors.green) : Colors.grey,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
    );
  }
}

class _NearbyDriver {
  final String id;
  final String name;
  final LatLng position;
  final double? distanceKm;
  final String? vehicleType;
  final String? plate;

  const _NearbyDriver({
    required this.id,
    required this.name,
    required this.position,
    required this.distanceKm,
    required this.vehicleType,
    required this.plate,
  });

  static _NearbyDriver? fromJson(Map<String, dynamic> json) {
    final latitude = _readDouble(json["vi_do"]);
    final longitude = _readDouble(json["kinh_do"]);
    if (latitude == null || longitude == null) return null;

    final vehicle = json["vehicle"];
    final vehicleMap = vehicle is Map
        ? Map<String, dynamic>.from(vehicle)
        : null;

    return _NearbyDriver(
      id: (json["id"] ?? "").toString(),
      name: (json["ho_ten"] ?? "Tài xế").toString(),
      position: LatLng(latitude, longitude),
      distanceKm: _readDouble(json["distance"]),
      vehicleType: vehicleMap?["loai_xe"]?.toString(),
      plate: vehicleMap?["bien_so"]?.toString(),
    );
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  IconData get icon {
    if (vehicleType == "xe_may") return Icons.two_wheeler;
    return Icons.local_taxi;
  }

  String get tooltip {
    final parts = <String>[name];
    if (distanceKm != null) {
      parts.add("${distanceKm!.toStringAsFixed(2)} km");
    }
    if (plate != null && plate!.isNotEmpty) {
      parts.add(plate!);
    }
    return parts.join(" • ");
  }
}
