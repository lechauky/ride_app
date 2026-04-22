// ===========================================
// CONTROLLER - TÀI XẾ (Driver)
// Thành viên 2 phụ trách file này
// ===========================================

const driverService = require('../services/driverService');

// PUT /api/drivers/location
const updateLocation = async (req, res) => {
    try {
        const { driver_id, vi_do, kinh_do, thanh_pho } = req.body;

        if (!driver_id || !vi_do || !kinh_do || !thanh_pho) {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng gửi đầy đủ thông tin vị trí.',
                data: null
            });
        }

        const result = await driverService.updateLocation({ driver_id, vi_do, kinh_do, thanh_pho });
        return res.status(200).json(result);

    } catch (error) {
        console.log('❌ Lỗi cập nhật vị trí tài xế:', error.message);

        if (error.isReadOnly) {
            return res.status(503).json({
                success: false,
                message: error.message,
                data: null
            });
        }

        return res.status(500).json({
            success: false,
            message: 'Lỗi hệ thống khi cập nhật vị trí.',
            data: null
        });
    }
};

// GET /api/drivers/nearby
const findNearby = async (req, res) => {
    try {
        const { vi_do, kinh_do, thanh_pho } = req.query;

        if (!vi_do || !kinh_do || !thanh_pho) {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng gửi tọa độ và thành phố để tìm tài xế.',
                data: null
            });
        }

        const result = await driverService.findNearby({ vi_do, kinh_do, thanh_pho });
        return res.status(200).json(result);

    } catch (error) {
        console.log('❌ Lỗi tìm tài xế gần:', error.message);
        return res.status(500).json({
            success: false,
            message: 'Lỗi hệ thống khi tìm tài xế.',
            data: null
        });
    }
};

module.exports = { updateLocation, findNearby };
