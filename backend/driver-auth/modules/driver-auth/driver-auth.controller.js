const service = require('./driver-auth.service');

// Cập nhật vị trí tài xế
async function updateLocation(req, res) {
  try {
    const { latitude, longitude, thanh_pho } = req.body;
    const userId = req.user.id; // Từ JWT token

    const result = await service.updateLocation({
      userId,
      latitude,
      longitude,
      thanh_pho
    });

    return res.status(200).json(result);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
}

// Tìm tài xế gần nhất
async function findNearestDrivers(req, res) {
  try {
    const { latitude, longitude, thanh_pho, loai_dich_vu, max_distance, limit } = req.body;

    const result = await service.findNearestDrivers({
      latitude,
      longitude,
      thanh_pho,
      loai_dich_vu,
      max_distance: max_distance || 5,
      limit: limit || 5
    });

    return res.status(200).json(result);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
}

// Lấy danh sách tài xế khả dụng
async function getAvailableDrivers(req, res) {
  try {
    const { thanh_pho } = req.body;

    const result = await service.getAvailableDriversList(thanh_pho);

    return res.status(200).json(result);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
}

// Cập nhật trạng thái khả dụng
async function updateAvailability(req, res) {
  try {
    const { is_available } = req.body;
    const driverId = req.user.driver_id; // Từ JWT token (nếu có)

    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: 'Không tìm thấy ID tài xế trong token'
      });
    }

    const result = await service.updateAvailability(driverId, is_available);

    return res.status(200).json(result);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
}

// Lấy thông tin chi tiết tài xế
async function getProfile(req, res) {
  try {
    const driverId = req.user.driver_id || req.params.driverId;

    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu ID tài xế'
      });
    }

    const result = await service.getProfile(driverId);

    return res.status(200).json(result);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
}

module.exports = {
  updateLocation,
  findNearestDrivers,
  getAvailableDrivers,
  updateAvailability,
  getProfile
};
