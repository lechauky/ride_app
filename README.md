# Ride App - Demo CSDL Phân Tán

Ứng dụng gọi xe phục vụ đồ án Cơ sở dữ liệu phân tán. Project gồm Flutter frontend, backend Node.js/Express và 4 SQL Server mô phỏng cụm dữ liệu theo vùng.

## Kiến Trúc Demo

| Thành phần | Công nghệ | Cách chạy | URL/port |
| --- | --- | --- | --- |
| Frontend | Flutter, `flutter_map` | Flutter web, Android emulator hoặc điện thoại thật | Flutter dev server |
| Backend API | Node.js/Express | Docker Compose hoặc chạy local | `5001`, `5002`, `6001`, `6002` |
| Database | SQL Server 2022 | Docker Compose | `50011`, `50021`, `60011`, `60021` |
| Bản đồ | OpenStreetMap qua `flutter_map` | Miễn phí, không cần API key | `https://tile.openstreetmap.org` |

Project đang dùng OpenStreetMap, không dùng Google Maps SDK trong Flutter, nên không cần API key Google Maps để build hoặc chạy demo.

## Yêu Cầu Máy

- Docker Desktop.
- Flutter SDK và Chrome nếu chạy web.
- Android Studio/Android Emulator nếu demo mobile.
- Node.js 18+ nếu muốn chạy backend ngoài Docker.
- RAM nên có tối thiểu 8GB vì SQL Server container khá nặng.

## Cài Đặt Sau Khi Clone

```powershell
git clone <repo-url>
cd ride_app
flutter pub get
```

Nếu chạy bằng Docker Compose đầy đủ, không cần tạo file `.env` cho backend. Docker Compose truyền biến môi trường trực tiếp vào container backend.

Chỉ cần tạo `backend/.env` khi chạy backend ngoài Docker:

```powershell
Copy-Item backend/.env.example backend/.env
```

Frontend Flutter không cần file `.env` và không cần Google Maps API key.

## Chạy Nhanh Bằng Docker Compose

Lệnh này build backend và chạy cả 4 SQL Server:

```powershell
docker compose up -d --build
docker compose ps
```

Backend được expose ra máy host:

| Vùng | Vai trò | URL |
| --- | --- | --- |
| HCM | Primary | `http://localhost:5001/api` |
| HN | Primary | `http://localhost:5002/api` |
| HCM | Backup | `http://localhost:6001/api` |
| HN | Backup | `http://localhost:6002/api` |

Port backup `6001/6002` dùng để demo chế độ chỉ đọc. Các request `GET` vẫn được phép, còn `POST/PUT/PATCH/DELETE` sẽ trả `503` với `read_only: true`.

Smoke test:

```powershell
curl.exe http://localhost:5001/api/health
curl.exe http://localhost:5002/api/health
curl.exe http://localhost:6001/api/health
curl.exe http://localhost:6002/api/health
```

## Seed Dữ Liệu Demo

Sau khi SQL Server container đã khởi động ổn định:

```powershell
cd backend
npm install
node database/seed-all.js
cd ..
```

Seed tạo database, bảng, user demo, tài xế, xe và dữ liệu chuyến đi mẫu cho cả HCM/HN.

Từ bản demo final, script seed không sinh random riêng cho replica nữa. Luồng seed là:

1. Tạo schema và dữ liệu demo trên primary HCM/HN.
2. Tạo schema replica HCM/HN.
3. Copy dữ liệu từ primary sang replica tương ứng.
4. Đặt database replica sang `READ_ONLY`.

Như vậy khi tắt primary để demo failover, dữ liệu đọc từ replica khớp với dữ liệu đã seed trên primary tại thời điểm seed.

## Chạy Backend Ngoài Docker

Dùng cách này khi muốn debug Node.js trực tiếp trên máy host:

```powershell
Copy-Item backend/.env.example backend/.env
cd backend
npm install
node start_all.js
```

Khi chạy ngoài Docker, các host database trong `backend/.env` để `localhost` vì backend kết nối qua port SQL Server đã expose ra máy host.

## Chạy Flutter Web

```powershell
flutter run -d chrome
```

Web mode mặc định gọi backend qua `localhost`.

## Chạy Android Emulator

```powershell
flutter devices
flutter run -d <device-id>
```

Android emulator mặc định gọi backend host qua `10.0.2.2`, không dùng `localhost`. Android Manifest đã bật `usesCleartextTraffic` để demo với backend HTTP local.

## Chạy Trên Điện Thoại Thật

Điện thoại thật không truy cập được `10.0.2.2`. Máy tính chạy Docker/backend và điện thoại phải cùng mạng Wi-Fi. Lấy IP LAN của máy tính, ví dụ `192.168.1.20`, rồi chạy:

```powershell
flutter run --dart-define=API_HOST=192.168.1.20
```

Nếu đổi port API:

```powershell
flutter run --dart-define=API_HOST=192.168.1.20 --dart-define=API_NAM_PRIMARY_PORT=5001 --dart-define=API_BAC_PRIMARY_PORT=5002
```

## Bản Đồ OpenStreetMap

Frontend dùng:

- `flutter_map`
- `latlong2`
- tile OpenStreetMap: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`

Không cần Google Maps API key. Với demo/lớp học có lượng truy cập nhỏ, tile public của OpenStreetMap phù hợp. Nếu triển khai thật hoặc tải lớn, nên dùng tile provider riêng hoặc self-host tile theo chính sách OpenStreetMap.

## Tài Khoản Demo

Mật khẩu chung cho tài khoản seed mẫu: `123456`.

Tài khoản khách:

- HCM: `khachhang22_hcm@gmail.com`
- HCM: `khachhang13_hcm@gmail.com`
- HN: `khachhang43_hn@gmail.com`
- HN: `khachhang10_hn@gmail.com`

Tài khoản tài xế:

- HCM: `taixe8_hcm@gmail.com`
- HCM: `taixe7_hcm@gmail.com`
- HN: `taixe6_hn@gmail.com`
- HN: `taixe12_hn@gmail.com`

Danh sách đầy đủ nằm trong `Danh_Sach_Tai_Khoan_Demo.txt`.

## Kiểm Tra API Tài Xế Gần Điểm Đón

Các bước test demo đầy đủ nằm trong `TEST_CASES_DEMO.md`.

PowerShell có alias `curl` trỏ tới `Invoke-WebRequest`, nên dùng `curl.exe` để gọi curl thật:

```powershell
curl.exe -X POST "http://localhost:5001/api/drivers/nearest" `
  -H "Content-Type: application/json" `
  --data-raw '{"latitude":10.7769,"longitude":106.7009,"thanh_pho":"HCM","max_distance":10,"limit":5}'

curl.exe -X POST "http://localhost:5002/api/drivers/nearest" `
  -H "Content-Type: application/json" `
  --data-raw '{"latitude":21.0285,"longitude":105.8542,"thanh_pho":"HN","max_distance":10,"limit":5}'
```

Kiểm tra backup port chặn ghi:

```powershell
curl.exe -X POST "http://localhost:6001/api/trips" `
  -H "Content-Type: application/json" `
  --data-raw '{"thanh_pho":"HCM"}'
```

Kết quả mong đợi: HTTP `503`, `success: false`, `read_only: true`.

Sau khi khách đặt chuyến thành công, FE hiển thị trạng thái `Đang tìm tài xế`. Màn theo dõi chuyến gọi `GET /api/trips/:tripId/details?thanh_pho=HCM|HN` định kỳ để chỉ hiển thị thông tin tài xế/xe thật sau khi tài xế nhận chuyến.

## Xử Lý Lỗi Thường Gặp

- `docker compose config --quiet` lỗi: kiểm tra Docker Desktop và cú pháp `docker-compose.yml`.
- Backend báo thiếu `.env` khi chạy local: tạo `backend/.env` từ `backend/.env.example`.
- Web không gọi được API: kiểm tra backend/container có expose port `5001/5002` không.
- Emulator không gọi được API: dùng `10.0.2.2`, không dùng `localhost`.
- Điện thoại thật không gọi được API: dùng IP LAN của máy tính và mở firewall cho port `5001/5002`.
- SQL Server chưa nhận kết nối ngay sau khi `docker compose up -d`: chờ 30-60 giây rồi seed lại.
