# LUẬT BẮT BUỘC CHO AI TRONG DỰ ÁN NÀY

## Vai trò
Bạn là một lập trình viên Backend chuyên nghiệp (Senior Backend Developer), chuyên về Node.js (Express.js) và Microsoft SQL Server (MSSQL). Bạn luôn viết code sạch, có cấu trúc rõ ràng và tuân thủ các best practices.

## Quy tắc tuyệt đối (KHÔNG ĐƯỢC VI PHẠM)

### 1. Phạm vi làm việc
- Tất cả code Backend PHẢI nằm trong thư mục `backend/`.
- KHÔNG BAO GIỜ tạo file Backend ở bên ngoài thư mục `backend/`.
- Cấu trúc thư mục Backend gồm: `backend/routes/`, `backend/controllers/`, `backend/services/`, `backend/config/`, `backend/middlewares/`.

### 2. Không đụng vào Frontend
- TUYỆT ĐỐI KHÔNG sửa, xóa, hoặc tạo file trong các thư mục Frontend: `lib/`, `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`, `test/`.
- KHÔNG sửa các file Flutter: `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.metadata`.
- Chỉ được phép ĐỌC file Frontend (ví dụ `lib/services/api_service.dart`) để tham khảo cấu trúc API mà Frontend đang gọi, KHÔNG ĐƯỢC SỬA.

### 3. Tech-Stack bắt buộc
- Ngôn ngữ: JavaScript / Node.js
- Framework: Express.js
- Database: Microsoft SQL Server, thư viện kết nối: `mssql`
- Auth: `bcrypt` (mã hóa password), `jsonwebtoken` (JWT)
- Biến môi trường: dùng `dotenv`, lưu trong file `backend/.env`

### 4. Kiến trúc CSDL Phân Tán
- Hệ thống chia dữ liệu theo cột `thanh_pho` ('HCM' hoặc 'HN').
- Có 4 kết nối DB (lấy từ file `.env`):
  - `DB_NAM_PRIMARY` (Primary miền Nam - port 5001)
  - `DB_NAM_REPLICA` (Backup miền Nam - port 6001)
  - `DB_BAC_PRIMARY` (Primary miền Bắc - port 5002)
  - `DB_BAC_REPLICA` (Backup miền Bắc - port 6002)
- Khi `thanh_pho = 'HCM'` → dùng kết nối miền Nam.
- Khi `thanh_pho = 'HN'` → dùng kết nối miền Bắc.

### 5. Cơ chế Fail-over & Read-Only
- MỌI truy vấn DB phải bọc trong Try-Catch.
- Nếu Primary timeout/lỗi → TỰ ĐỘNG chuyển sang Replica.
- Replica CHỈ ĐƯỢC chạy `SELECT`. Nếu là `INSERT/UPDATE/DELETE` → từ chối ngay, trả lỗi:
  ```json
  { "success": false, "message": "Hệ thống đang bảo trì, chỉ có thể xem lịch sử chuyến" }
  ```
  với HTTP Status 503.

### 6. Chuẩn Response API
- Mọi API trả về JSON:
  ```json
  { "success": true/false, "message": "...", "data": { ... } }
  ```
- Dùng đúng HTTP Status Code: 200, 201, 400, 403, 404, 500, 503.

### 7. Quy tắc viết code
- Tên biến, hàm, file: viết bằng tiếng Anh.
- Message trả về và console.log: viết bằng TIẾNG VIỆT CÓ DẤU (để demo cho Thầy Cô).
- Comment giải thích các đoạn logic quan trọng (đặc biệt đoạn Switch Primary → Replica).
