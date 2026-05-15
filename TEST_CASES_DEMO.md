# Test Cases Demo - Ride App CSDL Phân Tán

Tài liệu này dùng để demo nhanh với giảng viên các luồng FE, BE, DB, định tuyến HCM/HN, tài xế gần điểm đón và failover chỉ đọc.

## Checklist Chuẩn Bị

- Chạy Docker Compose:
  ```powershell
  docker compose up -d --build
  docker compose ps
  ```
- Seed DB nếu là máy mới hoặc vừa reset volume:
  ```powershell
  cd backend
  npm install
  node database/seed-all.js
  cd ..
  ```
  Script seed sẽ seed primary trước, copy dữ liệu sang replica cùng vùng, rồi đặt replica `READ_ONLY`.
- Chạy Flutter web:
  ```powershell
  flutter run -d chrome
  ```
- Chạy emulator:
  ```powershell
  flutter run -d <device-id>
  ```
- Nếu chạy điện thoại thật:
  ```powershell
  flutter run --dart-define=API_HOST=<IP_LAN>
  ```
- PowerShell phải dùng `curl.exe`, không dùng `curl` alias.

## Tài Khoản Demo

Mật khẩu chung: `123456`.

| Vai trò | HCM | HN |
| --- | --- | --- |
| Khách | `khachhang22_hcm@gmail.com` | `khachhang43_hn@gmail.com` |
| Khách | `khachhang13_hcm@gmail.com` | `khachhang10_hn@gmail.com` |
| Tài xế | `taixe8_hcm@gmail.com` | `taixe6_hn@gmail.com` |
| Tài xế | `taixe7_hcm@gmail.com` | `taixe12_hn@gmail.com` |

## TC01 - FE Chọn Khu Vực HCM/HN

**Mục tiêu:** Chứng minh khu vực khách chọn trên FE được dùng cho luồng đặt xe.

**Bước demo:**

1. Login bằng khách HCM: `khachhang22_hcm@gmail.com`.
2. Ở Home, chọn `HCM`.
3. Vào `Đặt xe`, quan sát map và marker tài xế gần HCM.
4. Quay lại Home, chọn `Hà Nội`.
5. Vào `Đặt xe`, quan sát map chuyển sang tọa độ Hà Nội và marker tài xế gần HN.

**Kết quả mong đợi:**

- Account HCM vẫn có thể chọn HN.
- Màn đặt xe dùng đúng khu vực đang chọn, không lấy cứng khu vực của tài khoản.

**Nói với giảng viên:** Khách có thể di chuyển sang thành phố khác, nên app định tuyến theo khu vực đang chọn trên FE.

## TC02 - Khách HCM Đặt Chuyến Ở HN

**Mục tiêu:** Chứng minh khách HCM có thể tạo chuyến ở DB HN, không lỗi khóa ngoại user.

**Bước demo FE:**

1. Login khách HCM.
2. Chọn khu vực `Hà Nội`.
3. Vào `Đặt xe`, nhập/chọn điểm đón và điểm đến.
4. Chọn loại xe, thanh toán.

**Kết quả mong đợi:**

- Tạo chuyến thành công.
- Chuyến có `thanh_pho = HN`.
- Backend tự đảm bảo user có mặt ở DB HN trước khi tạo trip.
- Sau khi thanh toán, app hiển thị `Đang tìm tài xế`, không hiện tài xế/biển số giả.
- Khi tài xế HN nhận chuyến, màn theo dõi chuyến tự cập nhật thông tin tài xế thật từ endpoint chi tiết chuyến.

**API smoke nếu cần:**

```powershell
curl.exe -X POST "http://localhost:5002/api/drivers/nearest" `
  -H "Content-Type: application/json" `
  --data-raw '{"latitude":21.0285,"longitude":105.8542,"thanh_pho":"HN","max_distance":10,"limit":5}'
```

**Nói với giảng viên:** User gốc có thể ở HCM, nhưng chuyến được ghi vào DB theo vùng đặt xe. Backend copy tối thiểu user sang DB đích để đảm bảo toàn vẹn khóa ngoại.

**API kiểm tra chi tiết chuyến sau khi tạo:**

```powershell
curl.exe -X GET "http://localhost:5002/api/trips/<TRIP_ID>/details?thanh_pho=HN" `
  -H "Authorization: Bearer <TOKEN_KHACH>"
```

**Kết quả mong đợi:** Nếu chưa có tài xế nhận, response vẫn `success: true` và `driver: null`; nếu đã có tài xế nhận, response có `driver` và `vehicle`.

## TC03 - Tài Xế HN Chỉ Thấy Chuyến HN

**Mục tiêu:** Chứng minh tài xế được đề xuất chuyến gần theo khu vực tài xế.

**Bước demo:**

1. Login tài xế HN: `taixe6_hn@gmail.com`.
2. Quan sát màn tài xế hiển thị `Khu vực hoạt động: Hà Nội`.
3. Sau khi khách tạo chuyến HN, tài xế HN chờ polling hoặc bấm làm mới.
4. Mở card chuyến mới.

**Kết quả mong đợi:**

- Tài xế HN thấy chuyến HN.
- Card chuyến có nhãn `Đề xuất khách gần`.
- Nếu backend có tọa độ tài xế, card hiển thị khoảng cách tới điểm đón.

**Nói với giảng viên:** Tài xế không tự chọn vùng; vùng hoạt động lấy từ account tài xế và backend chỉ query chuyến cùng `thanh_pho`.

## TC04 - Tài Xế HCM Chỉ Thấy Chuyến HCM

**Mục tiêu:** Chứng minh dữ liệu chuyến được phân vùng, tài xế HCM không nhận nhầm chuyến HN.

**Bước demo:**

1. Login tài xế HCM: `taixe8_hcm@gmail.com`.
2. Quan sát màn tài xế hiển thị `Khu vực hoạt động: TP.HCM`.
3. Tạo một chuyến HCM bằng khách.
4. Tài xế HCM bấm làm mới hoặc chờ polling.

**Kết quả mong đợi:**

- Tài xế HCM thấy chuyến HCM.
- Không thấy chuyến HN.

**Nói với giảng viên:** API `trips/pending/nearest` nhận `thanh_pho` theo account tài xế, nên chỉ lấy chuyến trong DB đúng vùng.

## TC05 - API Tài Xế Gần Điểm Đón

**Mục tiêu:** Chứng minh backend tính tài xế gần theo tọa độ điểm đón.

**HCM:**

```powershell
curl.exe -X POST "http://localhost:5001/api/drivers/nearest" `
  -H "Content-Type: application/json" `
  --data-raw '{"latitude":10.7769,"longitude":106.7009,"thanh_pho":"HCM","max_distance":10,"limit":5}'
```

**HN:**

```powershell
curl.exe -X POST "http://localhost:5002/api/drivers/nearest" `
  -H "Content-Type: application/json" `
  --data-raw '{"latitude":21.0285,"longitude":105.8542,"thanh_pho":"HN","max_distance":10,"limit":5}'
```

**Kết quả mong đợi:**

- Response có `success: true`.
- `data` có tối đa 5 tài xế.
- Mỗi tài xế có `ho_ten`, `vi_do`, `kinh_do`, `distance`, `vehicle`.

**Nói với giảng viên:** FE gửi tọa độ điểm đón, backend so sánh với tọa độ tài xế trong DB, lọc bán kính 10km và trả tài xế gần nhất.

## TC06 - Failover Primary Sập, Replica Chỉ Đọc

**Mục tiêu:** Chứng minh server phụ/replica chỉ cho xem, không cho ghi.

**API chặn ghi trực tiếp trên backup port:**

```powershell
curl.exe -X POST "http://localhost:6001/api/trips" `
  -H "Content-Type: application/json" `
  --data-raw '{"thanh_pho":"HCM"}'

curl.exe -X PUT "http://localhost:6002/api/drivers/available" `
  -H "Content-Type: application/json" `
  --data-raw '{"is_available":true,"thanh_pho":"HN"}'
```

**Kết quả mong đợi:** Cả hai request trả HTTP `503`, `success: false`, `read_only: true`.

**Bước demo HCM:**

1. Tắt primary HCM:
   ```powershell
   docker stop sql_nam_primary
   ```
2. Gọi API xem lịch sử hoặc API đọc nếu replica có dữ liệu.
3. Thử tạo chuyến HCM hoặc bật/tắt trạng thái tài xế.

**Kết quả mong đợi:**

- API đọc vẫn có thể hoạt động nếu replica đã có dữ liệu.
- API ghi trả lỗi dạng:
  ```json
  {
    "success": false,
    "read_only": true,
    "message": "Server chính đang bảo trì, hiện chỉ xem được dữ liệu"
  }
  ```

**Nói với giảng viên:** Khi primary sập, backend chuyển sang replica nhưng wrapper DB chặn lệnh ghi như INSERT/UPDATE/DELETE, đảm bảo replica chỉ đọc. Replica trong demo là bản copy sau seed, không phải replication realtime liên tục.

## TC07 - Khôi Phục Primary

**Mục tiêu:** Chứng minh hệ thống ghi lại bình thường sau khi primary quay lại.

**Bước demo:**

1. Khôi phục primary HCM:
   ```powershell
   docker start sql_nam_primary
   ```
2. Chờ 15-30 giây.
3. Tạo chuyến HCM lại.

**Kết quả mong đợi:**

- Tạo chuyến thành công.
- Không còn `read_only: true`.

**Nói với giảng viên:** Backend retry primary sau khoảng thời gian failover, khi primary kết nối lại thì thao tác ghi hoạt động lại.

## Lệnh Verify Nhanh

```powershell
flutter analyze --no-fatal-infos
flutter test
cd backend
npm test
cd ..
docker compose config --quiet
```
