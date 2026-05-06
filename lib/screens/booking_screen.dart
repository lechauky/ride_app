import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'ride_types_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final pickup = TextEditingController();
  final destination = TextEditingController();

  bool isValid = false;

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
      isValid = pickup.text.trim().isNotEmpty &&
          destination.text.trim().isNotEmpty;
    });
  }

  // Tính khoảng cách (km) bằng công thức Haversine
  double _calculateDistanceKm(LatLng a, LatLng b) {
    const R = 6371.0; // bán kính Trái Đất (km)
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return R * c;
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
      print(e);
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
      return;
    }

    // xin quyền
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("Không có quyền GPS");
      return;
    }

    // lấy vị trí
    Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
      accuracy: LocationAccuracy.high,
    ));

    LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      currentPosition = currentLatLng;
      pickupLatLng = currentLatLng;
      pickup.text = "${position.latitude}, ${position.longitude}";
    });

    // di chuyển map
    mapController.move(currentLatLng, 16);
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    if (pickupLatLng != null) {
      markers.add(Marker(
        point: pickupLatLng!,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.green, size: 40),
      ));
    } else {
      markers.add(Marker(
        point: currentPosition,
        width: 40,
        height: 40,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
      ));
    }

    if (destinationLatLng != null) {
      markers.add(Marker(
        point: destinationLatLng!,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }

    return markers;
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
                  setState(() {
                    if (isSelectingDestination) {
                      destinationLatLng = point;
                      destination.text = "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
                    } else {
                      pickupLatLng = point;
                      pickup.text = "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
                    }
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ride_app',
                ),
                MarkerLayer(
                  markers: _buildMarkers(),
                ),
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
                  SizedBox(height: 15), 
                  
                  _buildInput("Điểm đón (Nhấn vào đây rồi chạm bản đồ)", pickup, false),
                  SizedBox(height: 15),
                  _buildInput("Điểm đến (Nhấn vào đây rồi chạm bản đồ)", destination, true),
                  SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: isValid ? _onConfirmBooking : null,
                    child: Text("Xác nhận đặt xe"),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, bool isDest) {
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
          setState(() {
            if (controller == pickup) {
              pickupLatLng = pos;
            } else {
              destinationLatLng = pos;
            }
          });

          // Di chuyển camera
          mapController.move(pos, 16);
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
    );
  }
}