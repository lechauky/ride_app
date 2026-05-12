# Hướng dẫn chạy 4 Server SQL Server bằng Docker

File `docker-compose.yml` giúp tạo ra 4 máy chủ database hoàn toàn độc lập.

## 1. Bảng Port Database

*Lưu ý: Các port này dành riêng cho Database (port API thêm số 1 ở cuối) để dễ nhớ và không bị đụng độ với port API (5001/5002...)*

| Máy chủ | Port API | Port Database | Vai trò | User | Password |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Miền Nam (Primary)** | `5001` | `50011` | Ghi + Đọc (Read/Write) | rideapp | 123456 |
| **Miền Bắc (Primary)** | `5002` | `50021` | Ghi + Đọc (Read/Write) | rideapp | 123456 |
| **Miền Nam (Backup)** | `6001` | `60011` | Chỉ Đọc (Read-Only) | rideapp | 123456 |
| **Miền Bắc (Backup)** | `6002` | `60021` | Chỉ Đọc (Read-Only) | rideapp | 123456 |

## 2. Yêu cầu

- Cài đặt **Docker Desktop**: https://www.docker.com/products/docker-desktop
- RAM tối thiểu **8GB** (mỗi container SQL Server chiếm khoảng 2GB)

## 3. Cách chạy

```bash
# Bước 1: Mở Terminal tại thư mục gốc dự án (chứa file docker-compose.yml)
# Bước 2: Chạy lệnh
docker-compose up -d

# Bước 3: Kiểm tra 4 container đã chạy chưa
docker ps
```

Kết quả mong đợi: 4 container có trạng thái `Up`.

## 4. Nạp dữ liệu (Seeding) Tự động

Toàn bộ quá trình tạo Database, phân quyền và nạp dữ liệu (Users, Drivers, Trips) đã được tự động hóa bằng Javascript. 
Chỉ cần chạy 1 lệnh duy nhất này tại thư mục gốc:

```bash
cd backend
npm install
node database/seed-all.js
```

Sau khi chạy xong, hệ thống sẽ tự động có sẵn hàng trăm dòng dữ liệu thực tế cho bạn test.

## 5. Cách tắt
```bash
# Tắt nhưng giữ dữ liệu 
docker-compose down

# Tắt và xoá sạch dữ liệu (bắt đầu lại từ đầu)
docker-compose down -v
```

## 6. Test Fail-over

Muốn giả lập server sập để test Fail-over, chỉ cần tắt 1 container:

```bash
# Giả lập: Server Miền Nam (Primary) bị sập
docker stop sql_nam_primary

# Backend sẽ tự động nhảy sang Backup (Port 6001)!
# Khôi phục lại:
docker start sql_nam_primary
```

## 7. URL demo FE - BE - DB

Compose hiện tại dùng 5 container: 4 SQL Server và 1 backend Node.

Chạy đầy đủ:

```bash
docker compose up -d --build
```

Backend expose ra máy host:

| Miền | API | DB host port | DB trong Docker |
| :--- | :--- | :--- | :--- |
| Nam primary | `http://localhost:5001/api` | `50011` | `mssql-nam-primary:1433` |
| Bac primary | `http://localhost:5002/api` | `50021` | `mssql-bac-primary:1433` |
| Nam backup | `http://localhost:6001/api` | `60011` | `mssql-nam-replica:1433` |
| Bac backup | `http://localhost:6002/api` | `60021` | `mssql-bac-replica:1433` |

Kiểm tra nhanh:

```bash
curl http://localhost:5001/api/health
curl http://localhost:5002/api/health
```

Flutter web dùng mặc định `localhost`, Android emulator dùng mặc định `10.0.2.2`.
Nếu demo bằng điện thoại thật, truyền LAN IP của máy chạy Docker:

```bash
flutter run --dart-define=API_HOST=192.168.1.10
```

Nếu đổi port API:

```bash
flutter run --dart-define=API_HOST=192.168.1.10 --dart-define=API_NAM_PRIMARY_PORT=5001 --dart-define=API_BAC_PRIMARY_PORT=5002
```
