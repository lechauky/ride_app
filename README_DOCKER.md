# Docker cho cụm SQL Server phân tán

File `docker-compose.yml` trong repo hiện dùng để chạy 4 SQL Server độc lập cho demo phân tán. Backend Node.js chạy ngoài Docker bằng `node backend/start_all.js` và kết nối tới các database qua port host.

## Bảng port

| Service Compose | Container | API tương ứng | Port database trên máy host | Vai trò | User app | Password app |
| --- | --- | --- | --- | --- | --- | --- |
| `mssql-nam-primary` | `sql_nam_primary` | `5001` | `50011` | HCM Primary, đọc/ghi | `rideapp` | `123456` |
| `mssql-bac-primary` | `sql_bac_primary` | `5002` | `50021` | HN Primary, đọc/ghi | `rideapp` | `123456` |
| `mssql-nam-replica` | `sql_nam_replica` | `6001` | `60011` | HCM Replica, chỉ đọc | `rideapp` | `123456` |
| `mssql-bac-replica` | `sql_bac_replica` | `6002` | `60021` | HN Replica, chỉ đọc | `rideapp` | `123456` |

Mật khẩu `sa` trong Docker Compose là `123456Aa`. Backend dùng user ứng dụng `rideapp/123456` sau khi seed.

## Chạy database

```powershell
docker compose up -d
docker compose ps
```

Kết quả mong đợi: 4 container SQL Server ở trạng thái `Up`.

## Tạo file môi trường cho backend local

Backend hiện không nằm trong Docker Compose, vì vậy khi clone repo cần tạo `backend/.env` nếu muốn chạy backend trên máy host:

```powershell
Copy-Item backend/.env.example backend/.env
```

Các host database trong `.env.example` để là `localhost` vì backend chạy trên máy host và truy cập SQL Server qua port đã expose của Docker.

## Seed dữ liệu

Chạy sau khi container SQL Server đã khởi động ổn định:

```powershell
cd backend
npm install
node database/seed-all.js
cd ..
```

Script seed tạo database, schema, tài khoản demo, tài xế, xe và dữ liệu mẫu cho cả HCM/HN.

## Chạy backend API

```powershell
cd backend
node start_all.js
```

Các API được mở:

- HCM Primary: `http://localhost:5001/api`
- HN Primary: `http://localhost:5002/api`
- HCM Backup: `http://localhost:6001/api`
- HN Backup: `http://localhost:6002/api`

Kiểm tra nhanh:

```powershell
curl http://localhost:5001/api/health
curl http://localhost:5002/api/health
```

## Tắt hoặc reset dữ liệu

Tắt container nhưng giữ volume dữ liệu:

```powershell
docker compose down
```

Tắt và xóa toàn bộ dữ liệu để seed lại từ đầu:

```powershell
docker compose down -v
```

## Test failover

Ví dụ tắt primary miền Nam:

```powershell
docker stop sql_nam_primary
```

Backend sẽ chuyển request đọc sang replica HCM. Khôi phục lại:

```powershell
docker start sql_nam_primary
```

## Ghi chú nếu muốn Docker hóa backend

Nếu nhóm muốn Docker Compose chạy luôn backend, cần thêm Dockerfile/service cho Node.js và đổi host database trong env của backend từ `localhost` sang service name Compose như `mssql-nam-primary`, `mssql-bac-primary`, `mssql-nam-replica`, `mssql-bac-replica`. Thay đổi đó chưa có trong cấu hình hiện tại.
