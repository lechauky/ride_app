// ===========================================
// ROUTES - CHUYẾN ĐI (Trips)
// Thành viên 3 phụ trách file này
// ===========================================

const express = require('express');
const router = express.Router();
const tripController = require('../controllers/tripController');
const authMiddleware = require('../middlewares/auth');

// POST /api/trips - Tạo chuyến đi mới (Đặt xe)
router.post('/', authMiddleware, tripController.createTrip);

// GET /api/trips/history - Xem lịch sử chuyến đi
router.get('/history', authMiddleware, tripController.getHistory);

// PUT /api/trips/:id/status - Cập nhật trạng thái chuyến
router.put('/:id/status', authMiddleware, tripController.updateStatus);

module.exports = router;
