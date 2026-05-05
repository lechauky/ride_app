import 'package:flutter/foundation.dart';

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
}

class AuthStore {
  static final ValueNotifier<UserInfo?> currentUser = ValueNotifier<UserInfo?>(null);
  static String? token;

  static void login(UserInfo user, String jwt) {
    currentUser.value = user;
    token = jwt;
  }

  static void logout() {
    currentUser.value = null;
    token = null;
  }

  static bool get isLoggedIn => currentUser.value != null;
  static bool get isDriver => currentUser.value?.role == 1;
}
