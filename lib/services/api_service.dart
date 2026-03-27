import 'dart:convert';
import 'package:http/http.dart' as http;

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

  static Future<Map<String, dynamic>> post(
      String endpoint, String city, Map data) async {
    String primary = getPrimary(city);
    String backup = getBackup(city);

    try {
      final res = await http.post(
        Uri.parse("$primary/$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      return {"data": jsonDecode(res.body), "isBackup": false};
    } catch (e) {
      print("Primary fail → backup");

      final res = await http.post(
        Uri.parse("$backup/$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      return {"data": jsonDecode(res.body), "isBackup": true};
    }
  }
}