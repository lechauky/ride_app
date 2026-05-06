// ===========================================
// CONTROLLER - Thành viên 2 (Đức Huy)
// Nhiệm vụ: Nhận HTTP Request, gọi Service, trả Response
// ===========================================
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
    const { is_available, thanh_pho } = req.body;
    const driverId = req.user.driver_id; // Từ JWT token (nếu có)
    const city = thanh_pho || req.user.thanh_pho || 'HCM';
    const result = driverId
      ? await service.updateAvailability(driverId, is_available, city)
      : await service.updateAvailabilityByUser(req.user.id, is_available, city);

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
    const driverId = req.user?.driver_id || req.params.driverId;

    if (!driverId && !req.user?.id) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu ID tài xế'
      });
    }

    // Truyền thanh_pho từ JWT hoặc query để định tuyến đúng DB
    const city = req.query.thanh_pho || req.user?.thanh_pho || 'HCM';
    const result = driverId
      ? await service.getProfile(driverId, city)
      : await service.getProfileByUser(req.user.id, city);

    return res.status(200).json(result);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
}

async function saveVehicle(req, res) {
  try {
    const city = req.body.thanh_pho || req.user.thanh_pho || 'HCM';
    const result = await service.saveVehicle(req.user.id, {
      ...req.body,
      thanh_pho: city,
    });

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
  getProfile,
  saveVehicle
};
