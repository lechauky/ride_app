import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'booking_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String city = "HCM";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ride App"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Card chọn thành phố
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Chọn khu vực:",
                        style: TextStyle(fontSize: 16)),
                    DropdownButton<String>(
                      value: city,
                      items: ["HCM", "HN"].map((c) {
                        return DropdownMenuItem(
                            value: c, child: Text(c));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          city = value!;
                          LocationService.setCity(value);
                        });
                      },
                    )
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Nút đặt xe
            _buildButton(
              context,
              "Đặt xe",
              Icons.directions_car,
              Colors.blue,
              BookingScreen(),
            ),

            SizedBox(height: 20),

            // Nút lịch sử
            _buildButton(
              context,
              "Lịch sử",
              Icons.history,
              Colors.blue,
              HistoryScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, IconData icon,
      Color color, Widget screen) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 60),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}