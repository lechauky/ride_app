# Driver Auth Backend

API để quản lý vị trí tài xế và tìm tài xế gần nhất.

## Features

- 📍 **Cập nhật vị trí thời gian thực** - Tài xế có thể cập nhật vị trí GPS (vĩ độ, kinh độ)
- 🔍 **Tìm tài xế gần nhất** - Tìm danh sách tài xế gần điểm đón dựa trên khoảng cách GPS
- ✅ **Quản lý trạng thái** - Cập nhật trạng thái khả dụng của tài xế
- 📋 **Danh sách tài xế** - Lấy danh sách tài xế khả dụng theo thành phố
- 👤 **Thông tin chi tiết** - Lấy thông tin đầy đủ của tài xế

## Installation

```bash
npm install
```

## Setup Environment

Tạo file `.env` hoặc dùng file chung từ `../backend/.env`:

```
PORT=3001
DB_SERVER=localhost\SQLEXPRESS
DB_USER=sa
DB_PASSWORD=sa@123456
DB_NAME=RideApp_Nam
JWT_SECRET=your_secret_key
DB_ENCRYPT=false
DB_TRUST_SERVER_CERT=true
```

## Running

Development:
```bash
npm run dev
```

Production:
```bash
npm start
```

## API Endpoints

### 1. Cập nhật vị trí tài xế
```
POST /api/drivers/location
Authorization: Bearer {token}
Body: {
  "latitude": 10.7769,
  "longitude": 106.7009,
  "thanh_pho": "HCM"
}
```

### 2. Tìm tài xế gần nhất
```
POST /api/drivers/nearest
Body: {
  "latitude": 10.7769,
  "longitude": 106.7009,
  "thanh_pho": "HCM",
  "max_distance": 5,
  "limit": 5
}
```

### 3. Lấy danh sách tài xế khả dụng
```
POST /api/drivers/available
Body: {
  "thanh_pho": "HCM"
}
```

### 4. Cập nhật trạng thái khả dụng
```
PUT /api/drivers/availability
Authorization: Bearer {token}
Body: {
  "is_available": true
}
```

### 5. Lấy thông tin chi tiết tài xế
```
GET /api/drivers/profile/:driverId
```

### 6. Lấy thông tin tài xế hiện tại
```
GET /api/drivers/me
Authorization: Bearer {token}
```

## Database

Sử dụng SQL Server với các bảng:
- `users` - Thông tin người dùng
- `drivers` - Thông tin tài xế
- `vehicles` - Thông tin xe

## Location Calculation

Sử dụng công thức **Haversine** để tính khoảng cách GPS:

```javascript
distance = 2 * R * arcsin(sqrt(sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)))
```

Khoảng cách tính bằng **km**.

## Error Handling

Tất cả lỗi trả về format:
```json
{
  "success": false,
  "message": "Error message here"
}
```

## Author

Ride App Team
