# Ride App - Demo CSDL Phân Tán

Ứng dụng gọi xe phục vụ đồ án Cơ sở dữ liệu phân tán. Project gồm Flutter frontend, backend Node.js/Express và 4 SQL Server mô phỏng cụm dữ liệu theo vùng.

## Kiến trúc chạy demo

| Thành phần | Công nghệ | Cách chạy | URL/port chính |
| --- | --- | --- | --- |
| Frontend | Flutter, `flutter_map` | Flutter web hoặc Android emulator | Web chạy bằng Flutter dev server |
| Backend API | Node.js/Express | Chạy ngoài Docker bằng `node backend/start_all.js` | `5001`, `5002`, `6001`, `6002` |
| Database | SQL Server 2022 | Docker Compose | `50011`, `50021`, `60011`, `60021` |
| Bản đồ | OpenStreetMap qua `flutter_map` | Miễn phí, không cần API key | `https://tile.openstreetmap.org` |

Project không dùng Google Maps SDK trong Flutter, nên không cần API key Google Maps để build hoặc chạy demo.

## Yêu cầu máy

- Docker Desktop.
- Flutter SDK và Chrome nếu chạy web.
- Android Studio/Android Emulator nếu demo mobile.
- Node.js 18+ để chạy backend.
- RAM nên có tối thiểu 8GB vì SQL Server container khá nặng.

## Cài đặt sau khi clone

```powershell
git clone <repo-url>
cd ride_app

flutter pub get

cd backend
npm install
Copy-Item .env.example .env
cd ..
```

File `backend/.env` chỉ cần khi chạy backend ngoài Docker. Với cấu trúc hiện tại, backend đang chạy ngoài Docker nên người clone repo cần tạo file này từ `backend/.env.example`. Không cần tạo `.env` cho Flutter frontend và không cần Google Maps API key.

## Chạy database bằng Docker

```powershell
docker compose up -d
docker ps
```

Các container database cần ở trạng thái `Up` trước khi seed hoặc chạy backend.

## Seed dữ liệu demo

```powershell
cd backend
node database/seed-all.js
cd ..
```

Seed tạo database, bảng, user demo, tài xế, xe và dữ liệu chuyến đi mẫu cho hai vùng HCM/HN.

## Chạy backend

```powershell
cd backend
node start_all.js
```

Backend sẽ mở 4 API:

| Vùng | Vai trò | URL |
| --- | --- | --- |
| HCM | Primary | `http://localhost:5001/api` |
| HN | Primary | `http://localhost:5002/api` |
| HCM | Backup | `http://localhost:6001/api` |
| HN | Backup | `http://localhost:6002/api` |

Smoke test nhanh:

```powershell
curl http://localhost:5001/api/health
curl http://localhost:5002/api/health
```

## Chạy Flutter web

```powershell
flutter run -d chrome
```

Ở web mode, frontend gọi backend qua `localhost`, ví dụ `http://localhost:5001/api`.

## Chạy Android emulator

```powershell
flutter devices
flutter run -d <device-id>
```

Ở Android emulator, frontend gọi backend host qua `10.0.2.2`, không dùng `localhost`. Android manifest đã cho phép HTTP cleartext để demo với backend local.

## Chạy trên điện thoại thật

Điện thoại thật không truy cập được `10.0.2.2`. Máy tính chạy backend và điện thoại phải cùng mạng Wi-Fi, sau đó cần dùng IP LAN của máy tính, ví dụ:

```text
http://192.168.1.20:5001/api
http://192.168.1.20:5002/api
```

Hiện `lib/services/api_service.dart` đang tối ưu cho web và Android emulator. Nếu demo bằng điện thoại thật, đổi host native từ `10.0.2.2` sang IP LAN của máy chạy backend hoặc bổ sung cấu hình runtime trước khi build.

## Bản đồ OpenStreetMap

Frontend dùng:

- `flutter_map`
- `latlong2`
- tile OpenStreetMap: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`

Không cần Google Maps API key. Khi demo/làm bài tập với lượng truy cập nhỏ, tile public của OpenStreetMap phù hợp. Nếu triển khai thật hoặc tải lớn, cần dùng tile provider riêng hoặc self-host tile theo chính sách của OpenStreetMap.

## Tài khoản demo

Mật khẩu chung cho tài khoản seed mẫu: `123456`.

Một vài tài khoản khách:

- HCM: `khachhang22_hcm@gmail.com`
- HCM: `khachhang13_hcm@gmail.com`
- HN: `khachhang43_hn@gmail.com`
- HN: `khachhang10_hn@gmail.com`

Một vài tài khoản tài xế:

- HCM: `taixe8_hcm@gmail.com`
- HCM: `taixe7_hcm@gmail.com`
- HN: `taixe6_hn@gmail.com`
- HN: `taixe12_hn@gmail.com`

Danh sách đầy đủ nằm trong `Danh_Sach_Tai_Khoan_Demo.txt`.

## Lệnh kiểm tra hữu ích

```powershell
docker compose config --quiet
docker compose ps
dart analyze lib/screens/booking_screen.dart
```

Kiểm tra API tài xế gần điểm đón:

```powershell
curl -X POST http://localhost:5001/api/drivers/nearest `
  -H "Content-Type: application/json" `
  -d "{\"latitude\":10.7769,\"longitude\":106.7009,\"thanh_pho\":\"HCM\",\"max_distance\":10,\"limit\":5}"

curl -X POST http://localhost:5002/api/drivers/nearest `
  -H "Content-Type: application/json" `
  -d "{\"latitude\":21.0285,\"longitude\":105.8542,\"thanh_pho\":\"HN\",\"max_distance\":10,\"limit\":5}"
```

## Xử lý lỗi thường gặp

- Backend báo thiếu `.env`: chạy `Copy-Item backend/.env.example backend/.env`.
- App web không gọi được API: kiểm tra backend có đang chạy ở port `5001/5002` không.
- Emulator không gọi được API: dùng `10.0.2.2`, không dùng `localhost`.
- Điện thoại thật không gọi được API: dùng IP LAN của máy tính và mở firewall cho port `5001/5002`.
- SQL Server chưa nhận kết nối ngay sau khi `docker compose up -d`: chờ thêm 30-60 giây rồi seed lại.
