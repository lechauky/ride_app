import 'dart:convert';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;
import 'auth_store.dart';

class ApiService {
  static const String _configuredHost = String.fromEnvironment("API_HOST");
  static const String _namPrimaryPort = String.fromEnvironment(
    "API_NAM_PRIMARY_PORT",
    defaultValue: "5001",
  );
  static const String _bacPrimaryPort = String.fromEnvironment(
    "API_BAC_PRIMARY_PORT",
    defaultValue: "5002",
  );
  static const String _namBackupPort = String.fromEnvironment(
    "API_NAM_BACKUP_PORT",
    defaultValue: "6001",
  );
  static const String _bacBackupPort = String.fromEnvironment(
    "API_BAC_BACKUP_PORT",
    defaultValue: "6002",
  );

  static String get _host {
    if (_configuredHost.isNotEmpty) return _configuredHost;
    if (kIsWeb) return "localhost";
    if (defaultTargetPlatform == TargetPlatform.android) return "10.0.2.2";
    return "localhost";
  }

  static String get serverMienNam => "http://$_host:$_namPrimaryPort/api";
  static String get serverMienBac => "http://$_host:$_bacPrimaryPort/api";

  static String get backupMienNam => "http://$_host:$_namBackupPort/api";
  static String get backupMienBac => "http://$_host:$_bacBackupPort/api";

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
    String endpoint,
    String city,
    Map data,
  ) async {
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
        return {
          "data": {"success": false, "message": "Mất kết nối hoàn toàn"},
          "isBackup": true,
        };
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
        return {
          "data": {"success": false, "message": "Mất kết nối hoàn toàn"},
          "isBackup": true,
        };
      }
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    String city,
    Map data,
  ) async {
    String primary = getPrimary(city);
    String backup = getBackup(city);

    try {
      final res = await http.put(
        Uri.parse("$primary/$endpoint"),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      return {"data": jsonDecode(res.body), "isBackup": false};
    } catch (e) {
      print("Primary fail → backup PUT");
      try {
        final res = await http.put(
          Uri.parse("$backup/$endpoint"),
          headers: _getHeaders(),
          body: jsonEncode(data),
        );
        return {"data": jsonDecode(res.body), "isBackup": true};
      } catch (backupErr) {
        return {
          "data": {"success": false, "message": "Mất kết nối hoàn toàn"},
          "isBackup": true,
        };
      }
    }
  }
}
