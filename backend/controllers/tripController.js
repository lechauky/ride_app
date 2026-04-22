// ===========================================
// CONTROLLER - CHUYẾN ĐI (Trip)
// Thành viên 3 phụ trách file này
// ===========================================

const tripService = require('../services/tripService');

// POST /api/trips
const createTrip = async (req, res) => {
    try {
        const { ma_nguoi_dung, vi_do_diem_don, kinh_do_diem_don, dia_chi_diem_don,
            vi_do_diem_den, kinh_do_diem_den, dia_chi_diem_den, thanh_pho } = req.body;

        if (!ma_nguoi_dung || !dia_chi_diem_don || !dia_chi_diem_den || !thanh_pho) {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng điền đầy đủ thông tin chuyến đi.',
                data: null
            });
        }

        const result = await tripService.createTrip({
            ma_nguoi_dung, vi_do_diem_don, kinh_do_diem_don, dia_chi_diem_don,
            vi_do_diem_den, kinh_do_diem_den, dia_chi_diem_den, thanh_pho
        });
        return res.status(201).json(result);

    } catch (error) {
        console.log('❌ Lỗi tạo chuyến đi:', error.message);

        // Xử lý lỗi Read-Only (Primary sập, đang dùng Replica)
        if (error.isReadOnly) {
            return res.status(503).json({
                success: false,
                message: error.message,
                data: null
            });
        }

        return res.status(500).json({
            success: false,
            message: 'Lỗi hệ thống khi tạo chuyến đi.',
            data: null
        });
    }
};

// GET /api/trips/history
const getHistory = async (req, res) => {
    try {
        const { thanh_pho } = req.query;
        const ma_nguoi_dung = req.user.id;

        const result = await tripService.getHistory(ma_nguoi_dung, thanh_pho);
        return res.status(200).json(result);

    } catch (error) {
        console.log('❌ Lỗi lấy lịch sử:', error.message);
        return res.status(500).json({
            success: false,
            message: 'Lỗi hệ thống khi lấy lịch sử chuyến đi.',
            data: null
        });
    }
};

// PUT /api/trips/:id/status
const updateStatus = async (req, res) => {
    try {
        const tripId = req.params.id;
        const { trang_thai, thanh_pho } = req.body;

        const result = await tripService.updateStatus(tripId, trang_thai, thanh_pho);
        return res.status(200).json(result);

    } catch (error) {
        console.log('❌ Lỗi cập nhật trạng thái:', error.message);

        if (error.isReadOnly) {
            return res.status(503).json({
                success: false,
                message: error.message,
                data: null
            });
        }

        return res.status(500).json({
            success: false,
            message: 'Lỗi hệ thống khi cập nhật trạng thái.',
            data: null
        });
    }
};

module.exports = { createTrip, getHistory, updateStatus };
