import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInfo {
  final String id;
  final String email;
  final String hoTen;
  final String thanhPho;
  final int role; // 0 = Khách, 1 = Tài xế

  UserInfo({
    required this.id,
    required this.email,
    required this.hoTen,
    required this.thanhPho,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'ho_ten': hoTen,
    'thanh_pho': thanhPho,
    'role': role,
  };

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: json['id'],
    email: json['email'],
    hoTen: json['ho_ten'],
    thanhPho: json['thanh_pho'],
    role: json['role'],
  );
}

class AuthStore {
  static final ValueNotifier<UserInfo?> currentUser = ValueNotifier<UserInfo?>(null);
  static String? token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenStr = prefs.getString('token');
    final userStr = prefs.getString('user');
    
    if (tokenStr != null && userStr != null) {
      try {
        final userData = jsonDecode(userStr);
        token = tokenStr;
        currentUser.value = UserInfo.fromJson(userData);
      } catch (_) {
        await logout();
      }
    }
  }

  static Future<void> login(UserInfo user, String jwt) async {
    currentUser.value = user;
    token = jwt;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', jwt);
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  static Future<void> logout() async {
    currentUser.value = null;
    token = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static bool get isLoggedIn => currentUser.value != null;
  static bool get isDriver => currentUser.value?.role == 1;
}
