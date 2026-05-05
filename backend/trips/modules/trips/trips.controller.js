const service = require('./trips.service');

async function createTrip(req, res) {
  try {
    const payload = { ...req.body, ma_nguoi_dung: req.user?.id || req.body?.ma_nguoi_dung };
    const result = await service.createTrip(payload);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi tạo chuyến đi',
      error: error.message,
    });
  }
}

async function getTripHistoryByUserId(req, res) {
  try {
    if (req.user?.id && req.params.userId && req.user.id !== req.params.userId) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền xem lịch sử của người dùng khác',
      });
    }

    const result = await service.getTripHistoryByUserId(req.params.userId, req.query);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi lấy lịch sử chuyến đi',
      error: error.message,
    });
  }
}

module.exports = { createTrip, getTripHistoryByUserId };
