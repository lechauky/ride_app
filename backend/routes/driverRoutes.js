// ===========================================
// ROUTES - TÀI XẾ (Drivers)
// Thành viên 2 phụ trách file này
// ===========================================

const express = require('express');
const router = express.Router();
const driverController = require('../controllers/driverController');
const authMiddleware = require('../middlewares/auth');

// PUT /api/drivers/location - Cập nhật vị trí tài xế
router.put('/location', authMiddleware, driverController.updateLocation);

// GET /api/drivers/nearby - Tìm tài xế gần điểm đón
router.get('/nearby', authMiddleware, driverController.findNearby);

module.exports = router;
