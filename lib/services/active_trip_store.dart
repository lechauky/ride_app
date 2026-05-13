import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Thông tin chuyến đi đang chạy của khách (sau khi tài xế nhận cuốc)
class PassengerTripInfo {
  final String maChuyenDi;
  final String thanhPho;
  final String trangThai;
  final bool hasDriver;

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
    this.thanhPho = "HCM",
    this.trangThai = "cho_xu_ly",
    this.hasDriver = false,
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

  PassengerTripInfo copyWith({
    String? maChuyenDi,
    String? thanhPho,
    String? trangThai,
    bool? hasDriver,
    String? tenTaiXe,
    String? sdtTaiXe,
    double? diemDanhGiaTaiXe,
    String? bienSo,
    String? hangXe,
    String? mauXe,
    String? loaiXe,
    String? diaChiDon,
    String? diaChiDen,
    LatLng? diemDon,
    LatLng? diemDen,
    double? khoangCachKm,
    int? tongTien,
    String? phuongThucThanhToan,
    int? etaPhut,
  }) {
    return PassengerTripInfo(
      maChuyenDi: maChuyenDi ?? this.maChuyenDi,
      thanhPho: thanhPho ?? this.thanhPho,
      trangThai: trangThai ?? this.trangThai,
      hasDriver: hasDriver ?? this.hasDriver,
      tenTaiXe: tenTaiXe ?? this.tenTaiXe,
      sdtTaiXe: sdtTaiXe ?? this.sdtTaiXe,
      diemDanhGiaTaiXe: diemDanhGiaTaiXe ?? this.diemDanhGiaTaiXe,
      bienSo: bienSo ?? this.bienSo,
      hangXe: hangXe ?? this.hangXe,
      mauXe: mauXe ?? this.mauXe,
      loaiXe: loaiXe ?? this.loaiXe,
      diaChiDon: diaChiDon ?? this.diaChiDon,
      diaChiDen: diaChiDen ?? this.diaChiDen,
      diemDon: diemDon ?? this.diemDon,
      diemDen: diemDen ?? this.diemDen,
      khoangCachKm: khoangCachKm ?? this.khoangCachKm,
      tongTien: tongTien ?? this.tongTien,
      phuongThucThanhToan: phuongThucThanhToan ?? this.phuongThucThanhToan,
      etaPhut: etaPhut ?? this.etaPhut,
    );
  }

  PassengerTripInfo mergeDetail(Map<String, dynamic> json) {
    final driver = json["driver"];
    final driverMap = driver is Map ? Map<String, dynamic>.from(driver) : null;
    final vehicle = driverMap?["vehicle"];
    final vehicleMap = vehicle is Map
        ? Map<String, dynamic>.from(vehicle)
        : null;
    final assigned = driverMap != null;

    return copyWith(
      thanhPho: _readString(json, "thanh_pho", thanhPho),
      trangThai: _readString(json, "trang_thai", trangThai),
      hasDriver: assigned,
      tenTaiXe: assigned
          ? _readString(driverMap, "ho_ten", tenTaiXe)
          : tenTaiXe,
      sdtTaiXe: assigned
          ? _readString(driverMap, "so_dien_thoai", sdtTaiXe)
          : sdtTaiXe,
      diemDanhGiaTaiXe: assigned
          ? _readDouble(driverMap, "diem_danh_gia") ?? diemDanhGiaTaiXe
          : diemDanhGiaTaiXe,
      bienSo: assigned && vehicleMap != null
          ? _readString(vehicleMap, "bien_so", bienSo)
          : bienSo,
      hangXe: assigned && vehicleMap != null
          ? _readString(vehicleMap, "hang_xe", hangXe)
          : hangXe,
      mauXe: assigned && vehicleMap != null
          ? _readString(vehicleMap, "mau_xe", mauXe)
          : mauXe,
      loaiXe: assigned && vehicleMap != null
          ? _vehicleTypeLabel(_readString(vehicleMap, "loai_xe", loaiXe))
          : _readString(json, "ten_loai_dich_vu", loaiXe),
      diaChiDon: _readString(json, "dia_chi_diem_don", diaChiDon),
      diaChiDen: _readString(json, "dia_chi_diem_den", diaChiDen),
      diemDon:
          _latLngFromJson(json, "vi_do_diem_don", "kinh_do_diem_don") ??
          diemDon,
      diemDen:
          _latLngFromJson(json, "vi_do_diem_den", "kinh_do_diem_den") ??
          diemDen,
      khoangCachKm: _readDouble(json, "khoang_cach_km") ?? khoangCachKm,
      tongTien: _readInt(json, "so_tien") ?? tongTien,
      phuongThucThanhToan: _paymentLabel(
        _readString(json, "phuong_thuc", phuongThucThanhToan),
      ),
      etaPhut: assigned ? 5 : etaPhut,
    );
  }

  static String _readString(
    Map<String, dynamic>? json,
    String key,
    String fallback,
  ) {
    final value = json?[key];
    if (value == null) return fallback;
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }

  static double? _readDouble(Map<String, dynamic>? json, String key) {
    final value = json?[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _readInt(Map<String, dynamic>? json, String key) {
    final value = json?[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  static LatLng? _latLngFromJson(
    Map<String, dynamic> json,
    String latKey,
    String lonKey,
  ) {
    final lat = _readDouble(json, latKey);
    final lon = _readDouble(json, lonKey);
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  static String _paymentLabel(String id) {
    if (id == 'vi_dien_tu') return 'Ví điện tử';
    if (id == 'the_ngan_hang') return 'Thẻ ngân hàng';
    if (id == 'tien_mat') return 'Tiền mặt';
    return id;
  }

  static String _vehicleTypeLabel(String type) {
    if (type == 'xe_may') return 'Xe máy';
    if (type == 'o_to_4_cho') return 'Ô tô 4 chỗ';
    if (type == 'o_to_7_cho') return 'Ô tô 7 chỗ';
    return type;
  }
}

/// Store đơn giản cho chuyến đang chạy của khách.
/// Sử dụng `ValueNotifier` để các widget khác lắng nghe và cập nhật giao diện.
class ActiveTripStore {
  static final ValueNotifier<PassengerTripInfo?> currentTrip =
      ValueNotifier<PassengerTripInfo?>(null);

  static void startTrip(PassengerTripInfo trip) {
    currentTrip.value = trip;
  }

  static void updateTrip(PassengerTripInfo trip) {
    currentTrip.value = trip;
  }

  static void endTrip() {
    currentTrip.value = null;
  }

  static bool get isInTrip => currentTrip.value != null;
}
