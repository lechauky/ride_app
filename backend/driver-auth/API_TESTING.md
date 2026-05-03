# Driver Auth API - Test Examples

## 1. Cập nhật vị trí tài xế (POST /api/drivers/location)
```bash
curl -X POST http://localhost:3001/api/drivers/location \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
	"latitude": 10.7769,
	"longitude": 106.7009,
	"thanh_pho": "HCM"
  }'
```

## 2. Tìm tài xế gần nhất (POST /api/drivers/nearest)
```bash
curl -X POST http://localhost:3001/api/drivers/nearest \
  -H "Content-Type: application/json" \
  -d '{
	"latitude": 10.7769,
	"longitude": 106.7009,
	"thanh_pho": "HCM",
	"max_distance": 5,
	"limit": 5
  }'
```

## 3. Lấy danh sách tài xế khả dụng (POST /api/drivers/available)
```bash
curl -X POST http://localhost:3001/api/drivers/available \
  -H "Content-Type: application/json" \
  -d '{
	"thanh_pho": "HCM"
  }'
```

## 4. Cập nhật trạng thái khả dụng (PUT /api/drivers/availability)
```bash
curl -X PUT http://localhost:3001/api/drivers/availability \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
	"is_available": true
  }'
```

## 5. Lấy thông tin chi tiết tài xế (GET /api/drivers/profile/:driverId)
```bash
curl -X GET http://localhost:3001/api/drivers/profile/1
```

## 6. Lấy thông tin tài xế hiện tại (GET /api/drivers/me)
```bash
curl -X GET http://localhost:3001/api/drivers/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 7. Health Check
```bash
curl -X GET http://localhost:3001/api/health
```

---

## Postman Collection (JSON)

```json
{
  "info": {
	"name": "Driver Auth API",
	"schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
	{
	  "name": "Update Location",
	  "request": {
		"method": "POST",
		"header": [
		  {
			"key": "Authorization",
			"value": "Bearer {{jwt_token}}"
		  },
		  {
			"key": "Content-Type",
			"value": "application/json"
		  }
		],
		"body": {
		  "mode": "raw",
		  "raw": "{\"latitude\": 10.7769, \"longitude\": 106.7009, \"thanh_pho\": \"HCM\"}"
		},
		"url": {
		  "raw": "http://localhost:3001/api/drivers/location",
		  "protocol": "http",
		  "host": ["localhost"],
		  "port": "3001",
		  "path": ["api", "drivers", "location"]
		}
	  }
	},
	{
	  "name": "Find Nearest Drivers",
	  "request": {
		"method": "POST",
		"header": [
		  {
			"key": "Content-Type",
			"value": "application/json"
		  }
		],
		"body": {
		  "mode": "raw",
		  "raw": "{\"latitude\": 10.7769, \"longitude\": 106.7009, \"thanh_pho\": \"HCM\", \"max_distance\": 5, \"limit\": 5}"
		},
		"url": {
		  "raw": "http://localhost:3001/api/drivers/nearest",
		  "protocol": "http",
		  "host": ["localhost"],
		  "port": "3001",
		  "path": ["api", "drivers", "nearest"]
		}
	  }
	}
  ]
}
```
