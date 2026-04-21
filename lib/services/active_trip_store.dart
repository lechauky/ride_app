import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Thông tin chuyến đi đang chạy của khách (sau khi tài xế nhận cuốc)
class PassengerTripInfo {
  final String maChuyenDi;

  // Tài xế
  final String tenTaiXe;
  final String sdtTaiXe;
  final double diemDanhGiaTaiXe;
  final String bienSo;
  final String hangXe;
  final String mauXe;
  final String loaiXe;

  // Chuyến
  final String diaChiDon;
  final String diaChiDen;
  final LatLng? diemDon;
  final LatLng? diemDen;
  final double khoangCachKm;
  final int tongTien;
  final String phuongThucThanhToan;

  /// ETA (phút) tài xế tới điểm đón
  final int etaPhut;

  PassengerTripInfo({
    required this.maChuyenDi,
    required this.tenTaiXe,
    required this.sdtTaiXe,
    required this.diemDanhGiaTaiXe,
    required this.bienSo,
    required this.hangXe,
    required this.mauXe,
    required this.loaiXe,
    required this.diaChiDon,
    required this.diaChiDen,
    required this.diemDon,
    required this.diemDen,
    required this.khoangCachKm,
    required this.tongTien,
    required this.phuongThucThanhToan,
    required this.etaPhut,
  });
}

/// Store đơn giản cho chuyến đang chạy của khách.
/// Sử dụng `ValueNotifier` để các widget khác lắng nghe và cập nhật giao diện.
class ActiveTripStore {
  static final ValueNotifier<PassengerTripInfo?> currentTrip =
      ValueNotifier<PassengerTripInfo?>(null);

  static void startTrip(PassengerTripInfo trip) {
    currentTrip.value = trip;
  }

  static void endTrip() {
    currentTrip.value = null;
  }

  static bool get isInTrip => currentTrip.value != null;
}
