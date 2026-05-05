import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_store.dart';

class ApiService {
  static const serverMienNam = "http://10.0.2.2:5001/api";
  static const serverMienBac = "http://10.0.2.2:5002/api";

  static const backupMienNam = "http://10.0.2.2:6001/api";
  static const backupMienBac = "http://10.0.2.2:6002/api";

  static String getPrimary(String city) {
    return city == "HCM" ? serverMienNam : serverMienBac;
  }

  static String getBackup(String city) {
    return city == "HCM" ? backupMienNam : backupMienBac;
  }

  static Map<String, String> _getHeaders() {
    final headers = {"Content-Type": "application/json"};
    if (AuthStore.token != null) {
      headers["Authorization"] = "Bearer ${AuthStore.token}";
    }
    return headers;
  }

  static Future<Map<String, dynamic>> post(
      String endpoint, String city, Map data) async {
    String primary = getPrimary(city);
    String backup = getBackup(city);

    try {
      final res = await http.post(
        Uri.parse("$primary/$endpoint"),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      return {"data": jsonDecode(res.body), "isBackup": false};
    } catch (e) {
      print("Primary fail → backup");
      try {
        final res = await http.post(
          Uri.parse("$backup/$endpoint"),
          headers: _getHeaders(),
          body: jsonEncode(data),
        );
        return {"data": jsonDecode(res.body), "isBackup": true};
      } catch (backupErr) {
        return {"data": {"success": false, "message": "Mất kết nối hoàn toàn"}, "isBackup": true};
      }
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint, String city) async {
    String primary = getPrimary(city);
    String backup = getBackup(city);

    try {
      final res = await http.get(
        Uri.parse("$primary/$endpoint"),
        headers: _getHeaders(),
      );
      return {"data": jsonDecode(res.body), "isBackup": false};
    } catch (e) {
      print("Primary fail → backup GET");
      try {
        final res = await http.get(
          Uri.parse("$backup/$endpoint"),
          headers: _getHeaders(),
        );
        return {"data": jsonDecode(res.body), "isBackup": true};
      } catch (backupErr) {
        return {"data": {"success": false, "message": "Mất kết nối hoàn toàn"}, "isBackup": true};
      }
    }
  }
}