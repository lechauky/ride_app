import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  final List trips = [
    {"from": "A", "to": "B"},
    {"from": "C", "to": "D"},
    {"from": "E", "to": "F"},
  ];

  //const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lịch sử chuyến")),
      body: ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: trips.length,
        itemBuilder: (_, i) {
          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: ListTile(
              leading: Icon(Icons.directions_car, color: Colors.deepPurple),
              title: Text("${trips[i]['from']} → ${trips[i]['to']}"),
              subtitle: Text("Hoàn thành"),
            ),
          );
        },
      ),
    );
  }
}