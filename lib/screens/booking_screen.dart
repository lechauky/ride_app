import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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
  GoogleMapController? mapController;
  LatLng currentPosition = LatLng(10.762622, 106.660172); // TP.HCM
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  LatLng? pickupLatLng;
  LatLng? destinationLatLng;

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
  Future<LatLng?> getLatLngFromAddress(String address) async {
  try {
    List<Location> locations = await locationFromAddress(address);
    return LatLng(locations.first.latitude, locations.first.longitude);
  } catch (e) {
    print(e);
    return null;
  }
}

Future<void> getCurrentLocation() async {
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
  ),
);

  LatLng currentLatLng =
      LatLng(position.latitude, position.longitude);

  setState(() {
    markers.clear();
    markers.add(
      Marker(
        markerId: MarkerId("current"),
        position: currentLatLng,
        infoWindow: InfoWindow(title: "Vị trí của bạn"),
      ),
    );

    pickup.text =
        "${position.latitude}, ${position.longitude}";
  });

  // di chuyển map
  mapController?.animateCamera(
    CameraUpdate.newLatLngZoom(currentLatLng, 16),
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
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentPosition,
          zoom: 14,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        onTap: (LatLng position) {
          setState(() {
            markers.clear();
            markers.add(
              Marker(
                markerId: MarkerId("selected"),
                position: position,
              ),
            );

            pickup.text =
                "${position.latitude}, ${position.longitude}";
          });
        },
        markers: markers,
        polylines: polylines, 
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
            
            _buildInput("Điểm đón", pickup),
            SizedBox(height: 15),
            _buildInput("Điểm đến", destination),
            SizedBox(height: 30),

            ElevatedButton(
              onPressed: isValid
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Xác nhận đặt xe thành công 🚗")),
                      );
                    }
                  : null,
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

  Widget _buildInput(String label, TextEditingController controller) {
  return TextField(
    controller: controller,
    onSubmitted: (value) async {
      LatLng? pos = await getLatLngFromAddress(value);

      if (pos != null) {
        setState(() {
          if (controller == pickup) {
            pickupLatLng = pos;
            markers.add(
              Marker(
                markerId: MarkerId("pickup"),
                position: pos,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
              ),
            );
          } else {
            destinationLatLng = pos;
            markers.add(
              Marker(
                markerId: MarkerId("destination"),
                position: pos,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
              ),
            );
          }
        });

        // Di chuyển camera
        mapController?.animateCamera(
          CameraUpdate.newLatLng(pos),
        );
      }
    },
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(Icons.location_on),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
}