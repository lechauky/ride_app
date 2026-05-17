import 'dart:async';
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/active_trip_store.dart';
import '../services/auth_store.dart';
import 'booking_screen.dart';
import 'history_screen.dart';
import 'rating_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';
import 'passenger_trip_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool autoLoadBookingLocation;
  final bool enableTripPolling;
  final bool enableRatingLookup;

  const HomeScreen({
    super.key,
    this.autoLoadBookingLocation = true,
    this.enableTripPolling = true,
    this.enableRatingLookup = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String city;
  Timer? _tripTimer;
  bool _isRefreshingTrip = false;
  bool _isOpeningRating = false;

  @override
  void initState() {
    super.initState();
    city = AuthStore.currentUser.value?.thanhPho ?? "HCM";
    if (widget.enableTripPolling) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshActiveTrip());
      _tripTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _refreshActiveTrip(),
      );
    }
  }

  @override
  void dispose() {
    _tripTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshActiveTrip() async {
    if (_isRefreshingTrip || ActiveTripStore.currentTrip.value == null) return;
    _isRefreshingTrip = true;
    try {
      final updated = await ActiveTripStore.refreshCurrentTrip();
      if (!mounted || updated == null) return;
      if (ActiveTripStore.shouldPromptDriverRating(updated)) {
        _showCompletedRatingPrompt(updated);
      }
    } finally {
      _isRefreshingTrip = false;
    }
  }

  String _bannerTitle(PassengerTripInfo trip) {
    if (trip.trangThai == "hoan_thanh") return "Chuyến đã hoàn thành";
    if (trip.trangThai == "cho_xu_ly") return "Đang tìm tài xế";
    return "Đang trong chuyến";
  }

  String _bannerSubtitle(PassengerTripInfo trip) {
    if (trip.trangThai == "hoan_thanh") {
      return "Bấm để đánh giá tài xế ${trip.tenTaiXe}";
    }
    if (trip.hasDriver) return "Tài xế ${trip.tenTaiXe} • ${trip.bienSo}";
    return "Đang tìm tài xế trong ${trip.thanhPho}";
  }

  IconData _bannerIcon(PassengerTripInfo trip) {
    if (trip.trangThai == "hoan_thanh") return Icons.rate_review;
    if (trip.trangThai == "cho_xu_ly") return Icons.search;
    return Icons.directions_car;
  }

  void _openDriverRating(PassengerTripInfo trip) {
    ActiveTripStore.endTrip();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => RatingScreen(
          target: RatingTarget.driver,
          tripId: trip.maChuyenDi,
          thanhPho: trip.thanhPho,
          targetName: trip.tenTaiXe,
          targetSubInfo: "${trip.hangXe} • ${trip.bienSo}",
        ),
      ),
      (r) => false,
    );
  }

  void _showRatingUnavailableMessage(PassengerTripInfo? trip) {
    final message = trip == null
        ? "Chưa tìm thấy chuyến đã hoàn thành để đánh giá tài xế"
        : trip.trangThai == "hoan_thanh" && !trip.hasDriver
        ? "Chuyến đã hoàn thành nhưng chưa có thông tin tài xế để đánh giá"
        : "Chuyến hiện tại chưa hoàn thành nên chưa thể đánh giá tài xế";
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<PassengerTripInfo?> _resolveTripForRating() async {
    var trip = ActiveTripStore.currentTrip.value;
    if (trip != null) {
      final refreshed = await ActiveTripStore.refreshCurrentTrip();
      trip = refreshed ?? trip;
      if (trip.trangThai == "hoan_thanh" && trip.hasDriver) return trip;
      if (trip.trangThai == "hoan_thanh" && !trip.hasDriver) return trip;
    }

    if (!widget.enableRatingLookup) return trip;

    final user = AuthStore.currentUser.value;
    if (user == null) return trip;

    return await ActiveTripStore.findLatestCompletedTripForRating(
      userId: user.id,
      cities: [city, user.thanhPho, "HCM", "HN"],
    );
  }

  Future<void> _openRatingFromHome() async {
    if (_isOpeningRating) return;
    setState(() => _isOpeningRating = true);

    PassengerTripInfo? trip;
    try {
      trip = await _resolveTripForRating();
    } finally {
      if (mounted) setState(() => _isOpeningRating = false);
    }

    if (!mounted) return;

    if (trip != null && trip.trangThai == "hoan_thanh" && trip.hasDriver) {
      _openDriverRating(trip);
      return;
    }
    _showRatingUnavailableMessage(trip);
  }

  void _showCompletedRatingPrompt(PassengerTripInfo trip) {
    _tripTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 26),
            SizedBox(width: 8),
            Text("Chuyến đã hoàn thành"),
          ],
        ),
        content: Text(
          "Tài xế ${trip.tenTaiXe} đã hoàn thành chuyến đi.\nBạn có thể đánh giá tài xế để lưu phản hồi vào hệ thống.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ActiveTripStore.endTrip();
            },
            child: const Text("Bỏ qua"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _openDriverRating(trip);
            },
            child: const Text("Đánh giá tài xế"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.currentUser.value;
    final tenHienThi = user?.hoTen ?? "Khách";
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride App"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthStore.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hello banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Colors.deepPurple,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Xin chào, $tenHienThi",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          "Bạn muốn đi đâu hôm nay?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Banner: đang trong chuyến đi
            ValueListenableBuilder<PassengerTripInfo?>(
              valueListenable: ActiveTripStore.currentTrip,
              builder: (context, trip, _) {
                if (trip == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (trip.trangThai == "hoan_thanh") {
                          if (trip.hasDriver) {
                            _openDriverRating(trip);
                          } else {
                            _showRatingUnavailableMessage(trip);
                          }
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PassengerTripScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade600,
                              Colors.green.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _bannerIcon(trip),
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _bannerTitle(trip),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _bannerSubtitle(trip),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Card chọn thành phố
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_city, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text("Khu vực:", style: TextStyle(fontSize: 15)),
                      ],
                    ),
                    DropdownButton<String>(
                      value: city,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: "HCM", child: Text("HCM")),
                        DropdownMenuItem(value: "HN", child: Text("Hà Nội")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          city = value!;
                          LocationService.setCity(value);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Dịch vụ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _menu(
                  icon: Icons.directions_car,
                  label: "Đặt xe",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(
                          thanhPho: city,
                          autoLoadLocation: widget.autoLoadBookingLocation,
                        ),
                      ),
                    );
                  },
                ),
                _menu(
                  icon: Icons.star_rate,
                  label: "Đánh giá",
                  color: Colors.amber,
                  onTap: () {
                    _openRatingFromHome();
                  },
                ),
                _menu(
                  icon: Icons.notifications,
                  label: "Thông báo",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                _menu(
                  icon: Icons.history,
                  label: "Lịch sử",
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HistoryScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
