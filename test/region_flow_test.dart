import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/screens/active_trip_screen.dart';
import 'package:ride_app/screens/booking_screen.dart';
import 'package:ride_app/screens/driver_home_screen.dart';
import 'package:ride_app/screens/home_screen.dart';
import 'package:ride_app/screens/payment_screen.dart';
import 'package:ride_app/screens/rating_screen.dart';
import 'package:ride_app/screens/ride_types_screen.dart';
import 'package:ride_app/services/auth_store.dart';
import 'package:ride_app/services/location_service.dart';

Widget _app(Widget child) => MaterialApp(home: child);

UserInfo _user({String city = 'HCM', int role = 0}) {
  return UserInfo(
    id: 'user-1',
    email: 'demo@example.com',
    hoTen: role == 1 ? 'Tài xế Demo' : 'Khách Demo',
    thanhPho: city,
    role: role,
  );
}

void main() {
  tearDown(() {
    AuthStore.currentUser.value = null;
    AuthStore.token = null;
    LocationService.setCity('HCM');
  });

  test('LocationService lưu khu vực khách chọn', () {
    expect(LocationService.getCity(), 'HCM');

    LocationService.setCity('HN');
    expect(LocationService.getCity(), 'HN');

    LocationService.setCity('HCM');
    expect(LocationService.getCity(), 'HCM');
  });

  testWidgets('khách HCM chọn HN thì BookingScreen dùng HN', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AuthStore.currentUser.value = _user(city: 'HCM');

    await tester.pumpWidget(
      _app(const HomeScreen(autoLoadBookingLocation: false)),
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hà Nội').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đặt xe'));
    await tester.pumpAndSettle();

    final booking = tester.widget<BookingScreen>(find.byType(BookingScreen));
    expect(booking.thanhPho, 'HN');
  });

  testWidgets('RideTypesScreen truyền khu vực sang PaymentScreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const RideTypesScreen(
          thanhPho: 'HN',
          khoangCachKm: 2,
          diaChiDon: 'Hồ Gươm',
          diaChiDen: 'Cầu Giấy',
        ),
      ),
    );

    await tester.tap(find.text('Tiếp tục thanh toán'));
    await tester.pumpAndSettle();

    final payment = tester.widget<PaymentScreen>(find.byType(PaymentScreen));
    expect(payment.thanhPho, 'HN');
  });

  testWidgets('màn tài xế hiển thị khu vực HCM/HN theo account', (
    tester,
  ) async {
    AuthStore.currentUser.value = _user(city: 'HCM', role: 1);
    await tester.pumpWidget(_app(const DriverHomeScreen(enablePolling: false)));
    expect(find.text('Khu vực hoạt động: TP.HCM'), findsOneWidget);

    AuthStore.currentUser.value = _user(city: 'HN', role: 1);
    await tester.pumpWidget(_app(const DriverHomeScreen(enablePolling: false)));
    expect(find.text('Khu vực hoạt động: Hà Nội'), findsOneWidget);
  });

  test('TripRequest parse khu vực và khoảng cách tới tài xế', () {
    final trip = TripRequest.fromJson({
      'ma_chuyen_di': 'trip-1',
      'thanh_pho': 'HN',
      'ten_khach': 'Khách HN',
      'so_dien_thoai': '0900000000',
      'diem_danh_gia_khach': 4.8,
      'dia_chi_diem_don': 'Hồ Gươm',
      'dia_chi_diem_den': 'Cầu Giấy',
      'khoang_cach_km': 6.2,
      'so_tien': 90000,
      'ma_loai_dich_vu': 'car4',
      'phuong_thuc': 'tien_mat',
      'khoang_cach_den_tai_xe_km': 1.23,
    });

    expect(trip.thanhPho, 'HN');
    expect(trip.diemDon.latitude, 21.028511);
    expect(trip.diemDon.longitude, 105.854165);
    expect(trip.khoangCachDenTaiXeKm, 1.23);
  });

  testWidgets('RatingScreen không dùng tên tài xế hoặc khách mẫu cố định', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const RatingScreen(
          target: RatingTarget.driver,
          tripId: 'trip-1',
          thanhPho: 'HN',
          targetName: 'Tài xế Hà Nội',
          targetSubInfo: 'VinFast • 30A-12345',
        ),
      ),
    );

    expect(find.text('Tài xế Hà Nội'), findsOneWidget);
    expect(find.text('VinFast • 30A-12345'), findsOneWidget);
    expect(find.text('Nguyễn Văn A'), findsNothing);
    expect(find.text('Trần Thị B'), findsNothing);

    final rating = tester.widget<RatingScreen>(find.byType(RatingScreen));
    expect(rating.thanhPho, 'HN');
  });
}
