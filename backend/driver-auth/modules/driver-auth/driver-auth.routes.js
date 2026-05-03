const express = require('express');
const controller = require('./driver-auth.controller');
const authMiddleware = require('../../middleware/authMiddleware');

const router = express.Router();

/**
 * POST /api/drivers/location
 * Cập nhật vị trí thời gian thực của tài xế
 * Body: { latitude, longitude, thanh_pho }
 */
router.post('/location', authMiddleware, controller.updateLocation);

/**
 * POST /api/drivers/nearest
 * Tìm tài xế gần nhất với điểm đón
 * Body: { latitude, longitude, thanh_pho, max_distance?, limit? }
 */
router.post('/nearest', controller.findNearestDrivers);

/**
 * POST /api/drivers/available
 * Lấy danh sách tài xế khả dụng theo thành phố
 * Body: { thanh_pho }
 */
router.post('/available', controller.getAvailableDrivers);

/**
 * PUT /api/drivers/availability
 * Cập nhật trạng thái khả dụng của tài xế
 * Body: { is_available }
 */
router.put('/availability', authMiddleware, controller.updateAvailability);

/**
 * GET /api/drivers/profile/:driverId
 * Lấy thông tin chi tiết tài xế
 */
router.get('/profile/:driverId', controller.getProfile);

/**
 * GET /api/drivers/me
 * Lấy thông tin tài xế hiện tại (từ token)
 */
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const driverId = req.user.driver_id;
    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: 'Không tìm thấy ID tài xế'
      });
    }
    req.params.driverId = driverId;
    return controller.getProfile(req, res);
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;
