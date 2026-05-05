import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_store.dart';

class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List trips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final user = AuthStore.currentUser.value;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }
    try {
      final res = await ApiService.get('trips/history/${user.id}?thanh_pho=${user.thanhPho}', user.thanhPho);
      final data = res["data"];
      if (data != null && data["success"] == true) {
        setState(() {
          trips = data["data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lịch sử chuyến")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? const Center(child: Text("Không có lịch sử chuyến đi"))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: trips.length,
                  itemBuilder: (_, i) {
                    final t = trips[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: ListTile(
                        leading: const Icon(Icons.history, color: Colors.deepPurple),
                        title: Text("${t['dia_chi_diem_don']} → ${t['dia_chi_diem_den']}",
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text("Trạng thái: ${t['trang_thai']} - ${t['khoang_cach_km'] ?? '?'} km"),
                      ),
                    );
                  },
                ),
    );
  }
}