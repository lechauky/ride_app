# Docker Cho Cụm SQL Server Và Backend

File `docker-compose.yml` chạy 4 SQL Server độc lập và 1 backend Node.js cho demo CSDL phân tán.

## Bảng Port

| Service Compose | Container | API tương ứng | Port database host | Database trong Docker | Vai trò |
| --- | --- | --- | --- | --- | --- |
| `mssql-nam-primary` | `sql_nam_primary` | `5001` | `50011` | `mssql-nam-primary:1433` | HCM primary, đọc/ghi |
| `mssql-bac-primary` | `sql_bac_primary` | `5002` | `50021` | `mssql-bac-primary:1433` | HN primary, đọc/ghi |
| `mssql-nam-replica` | `sql_nam_replica` | `6001` | `60011` | `mssql-nam-replica:1433` | HCM replica, chỉ đọc |
| `mssql-bac-replica` | `sql_bac_replica` | `6002` | `60021` | `mssql-bac-replica:1433` | HN replica, chỉ đọc |
| `backend` | `ride_app_backend` | `5001/5002/6001/6002` | none | kết nối bằng service name | Node.js API |

Mật khẩu `sa` của SQL Server container là `123456Aa`. Backend dùng user ứng dụng `rideapp/123456` sau khi seed.

## Chạy Đầy Đủ Bằng Docker Compose

```powershell
docker compose up -d --build
docker compose ps
```

Kết quả mong đợi:

- 4 SQL Server container ở trạng thái `Up`.
- `ride_app_backend` ở trạng thái `Up`.
- API host truy cập được qua `localhost:5001`, `localhost:5002`, `localhost:6001`, `localhost:6002`.

## Biến Môi Trường Backend Trong Docker

Docker Compose truyền trực tiếp các biến:

- `DB_NAM_PRIMARY_SERVER=mssql-nam-primary`
- `DB_BAC_PRIMARY_SERVER=mssql-bac-primary`
- `DB_NAM_REPLICA_SERVER=mssql-nam-replica`
- `DB_BAC_REPLICA_SERVER=mssql-bac-replica`

Vì backend chạy trong Docker network, backend phải kết nối database bằng Compose service name, không dùng `localhost`.

## Khi Nào Cần backend/.env?

Không cần `backend/.env` nếu chạy backend bằng Docker Compose.

Cần `backend/.env` nếu chạy backend ngoài Docker trên máy host:

```powershell
Copy-Item backend/.env.example backend/.env
```

Lúc này host database trong `.env` để `localhost` vì SQL Server đã expose port ra máy host.

## Seed Dữ Liệu

Chạy sau khi SQL Server đã khởi động ổn định:

```powershell
cd backend
npm install
node database/seed-all.js
cd ..
```

Script seed tạo database, schema, tài khoản demo, tài xế, xe và dữ liệu mẫu cho HCM/HN.

## Kiểm Tra API

```powershell
curl http://localhost:5001/api/health
curl http://localhost:5002/api/health
```

Kiểm tra tài xế gần điểm đón:

```powershell
curl -X POST http://localhost:5001/api/drivers/nearest `
  -H "Content-Type: application/json" `
  -d "{\"latitude\":10.7769,\"longitude\":106.7009,\"thanh_pho\":\"HCM\",\"max_distance\":10,\"limit\":5}"
```

## Tắt Hoặc Reset Dữ Liệu

Tắt container nhưng giữ volume dữ liệu:

```powershell
docker compose down
```

Tắt và xóa toàn bộ dữ liệu để seed lại từ đầu:

```powershell
docker compose down -v
```

## Test Failover

Tắt primary miền Nam:

```powershell
docker stop sql_nam_primary
```

Backend sẽ chuyển request đọc sang replica HCM. Khôi phục:

```powershell
docker start sql_nam_primary
```
