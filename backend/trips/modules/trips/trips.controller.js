const service = require('./trips.service');
const { mapReadOnlyResult } = require('../../../utils/readOnly');

async function createTrip(req, res) {
  try {
    const payload = {
      ...req.body,
      ma_nguoi_dung: req.user?.id || req.body?.ma_nguoi_dung,
      ma_nguoi_dung_thanh_pho:
        req.user?.thanh_pho || req.body?.ma_nguoi_dung_thanh_pho,
    };
    const result = await service.createTrip(payload);
    return res.status(result.status).json(result.body);
  } catch (error) {
    const readOnly = mapReadOnlyResult(error);
    if (readOnly) return res.status(readOnly.status).json(readOnly.body);
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
    const readOnly = mapReadOnlyResult(error);
    if (readOnly) return res.status(readOnly.status).json(readOnly.body);
    return res.status(500).json({
      success: false,
      message: 'Lỗi lấy lịch sử chuyến đi',
      error: error.message,
    });
  }
}

async function getNearestPendingTrips(req, res) {
  try {
    const result = await service.getNearestPendingTrips(req.query, req.user);
    return res.status(result.status).json(result.body);
  } catch (error) {
    const readOnly = mapReadOnlyResult(error);
    if (readOnly) return res.status(readOnly.status).json(readOnly.body);
    return res.status(500).json({
      success: false,
      message: 'Lỗi lấy chuyến đang chờ',
      error: error.message,
    });
  }
}

async function getTripDetails(req, res) {
  try {
    const result = await service.getTripDetails(req.params.tripId, req.query, req.user);
    return res.status(result.status).json(result.body);
  } catch (error) {
    const readOnly = mapReadOnlyResult(error);
    if (readOnly) return res.status(readOnly.status).json(readOnly.body);
    return res.status(500).json({
      success: false,
      message: 'Lỗi lấy chi tiết chuyến đi',
      error: error.message,
    });
  }
}

async function acceptTrip(req, res) {
  try {
    const result = await service.acceptTrip(req.params.tripId, req.user, req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    const readOnly = mapReadOnlyResult(error);
    if (readOnly) return res.status(readOnly.status).json(readOnly.body);
    return res.status(500).json({
      success: false,
      message: 'Lỗi nhận chuyến',
      error: error.message,
    });
  }
}

async function rejectTrip(req, res) {
  try {
    const result = await service.rejectTrip(req.params.tripId, req.user, req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    const readOnly = mapReadOnlyResult(error);
    if (readOnly) return res.status(readOnly.status).json(readOnly.body);
    return res.status(500).json({
      success: false,
      message: 'Lỗi từ chối chuyến',
      error: error.message,
    });
  }
}

async function completeTrip(req, res) {
  try {
    const result = await service.completeTrip(req.params.tripId, req.user, req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    const readOnly = mapReadOnlyResult(error);
    if (readOnly) return res.status(readOnly.status).json(readOnly.body);
    return res.status(500).json({
      success: false,
      message: 'Lỗi hoàn thành chuyến',
      error: error.message,
    });
  }
}

async function saveRating(req, res) {
  try {
    const result = await service.saveRating(req.params.tripId, req.user, req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    const readOnly = mapReadOnlyResult(error);
    if (readOnly) return res.status(readOnly.status).json(readOnly.body);
    return res.status(500).json({
      success: false,
      message: 'Lỗi lưu đánh giá',
      error: error.message,
    });
  }
}

module.exports = {
  createTrip,
  getTripHistoryByUserId,
  getNearestPendingTrips,
  getTripDetails,
  acceptTrip,
  rejectTrip,
  completeTrip,
  saveRating,
};
