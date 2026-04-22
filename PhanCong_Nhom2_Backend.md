# BẢNG PHÂN CÔNG CÔNG VIỆC NHÓM 2 (BACKEND - CORE SYSTEM)
## Đồ án: Ứng dụng Gọi xe theo Vị trí (Hệ QTCSDL Phân Tán)

### I. THÔNG TIN CHUNG & QUY ĐỊNH KỸ THUẬT
- **Ngôn ngữ / Framework Backend:** Node.js (dùng Express.js để viết REST API).
- **Hệ cơ sở dữ liệu (Liên hệ Nhóm 3):** Microsoft SQL Server (MSSQL).
- **Thư viện tương tác:** Dùng module `mssql` trong Node.js để thực thi Query. 
- **Cơ chế hoạt động hệ thống:** Hệ thống phân mảnh dữ liệu theo biến số `thanh_pho` (HCM / HN). Yêu cầu khắt khe nhất của đồ án là kịch bản **Fail-over**: 
  - Khi Server CSDL chính (Primary) sập -> Backend phải điều hướng (try-catch) nhảy tự động sang Server CSDL dự phòng (Replica). 
  - Tại trạm Replica này, Backend chỉ được phép thực thi câu lệnh `SELECT` (Read-only) để xem lịch sử, nghiêm cấm việc Ghi dữ liệu (INSERT - Đặt xe).

### II. KIẾN TRÚC MẠNG VÀ PORT 
Nhóm 2 phải đảm nhiệm mở Server khớp với các Port mà App Front-end đã gắn cứng:
- **Backend Miền Nam (Primary):** `http://localhost:5001/api`
- **Backend Miền Bắc (Primary):** `http://localhost:5002/api`
- **Backend Backup Miền Nam:** `http://localhost:6001/api`
- **Backend Backup Miền Bắc:** `http://localhost:6002/api`

### III. BẢNG PHÂN CÔNG CHI TIẾT (5 THÀNH VIÊN)

| Thành viên | Phụ trách chính | Trách nhiệm và Phạm vi công việc |
| :--- | :--- | :--- |
| **Khánh** | **Quản lý Tài khoản (User & Auth API)** | - Viết API chức năng Đăng ký / Đăng nhập (Mã hóa mật khẩu với Bcrypt).<br>- Tạo middleware bảo vệ luồng truy cập bằng JWT (Xác thực Token).<br>- Tương tác với bảng `users`. |
| **Đức Huy*** | **Quản lý Tài xế (Driver API)** | - Viết API cập nhật vị trí thời gian thực (Vĩ độ, kinh độ) của Tài xế.<br>- Xây dựng logic tìm tài xế gần nhất với điểm đón (So khớp khoảng cách GPS).<br>- Tương tác với bảng `drivers`. |
| **Khang** | **Quản lý Chuyến đi (Trips Core API)** | - Viết API cốt lõi: Đặt chuyến xe mới (Lưu thông tin điểm đi/điểm đến tọa độ GPS).<br>- Viết API Lấy danh sách Lịch sử các chuyến đi theo User ID.<br>- Tương tác với bảng `trips`. |
| **Quốc Huy** | **Data Access & Routing Logic** | - Cấu hình file kết nối SQL Server Node.js (nhận 4 chuỗi kết nối từ nhóm 3).<br>- Viết logic Định tuyến Query: Phân tích Request (VD: `thanh_pho = HCM`) để trỏ connection tới đúng CSDL miền Nam. |
| **Đạt** | **Bắt Rớt Mạng (Fail-over) & Read-Only** | - Viết mã Try-Catch bảo vệ kết nối, tự động phát hiện đứt mạng với Primary.<br>- Implement cơ chế Read-Only: Nếu nhảy sang máy chủ Replica, chèn Regex/Logic chặn đứng ngay câu lệnh `INSERT` (Đặt xe). Trả về lỗi: *"Hệ thống bảo trì, chỉ xem được lịch sử"*. |


---
