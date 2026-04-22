// ===========================================
// SERVICE - CHUYẾN ĐI (Trip)
// Thành viên 3 phụ trách hoàn thiện file này
// TV3: Viết logic đặt xe, lấy lịch sử, cập nhật trạng thái
// ===========================================

const { executeWithFailover } = require('../middlewares/failover');

// TODO (TV3): Hoàn thiện logic tạo chuyến đi
const createTrip = async ({ ma_nguoi_dung, vi_do_diem_don, kinh_do_diem_don, dia_chi_diem_don,
    vi_do_diem_den, kinh_do_diem_den, dia_chi_diem_den, thanh_pho }) => {
    const query = `INSERT INTO trips (ma_nguoi_dung, vi_do_diem_don, kinh_do_diem_don, dia_chi_diem_don,
                   vi_do_diem_den, kinh_do_diem_den, dia_chi_diem_den, trang_thai, thanh_pho)
                 VALUES (@ma_nguoi_dung, @vi_do_diem_don, @kinh_do_diem_don, @dia_chi_diem_don,
                   @vi_do_diem_den, @kinh_do_diem_den, @dia_chi_diem_den, 'cho_xu_ly', @thanh_pho)`;

    await executeWithFailover(thanh_pho, query, {
        ma_nguoi_dung, vi_do_diem_don, kinh_do_diem_don, dia_chi_diem_don,
        vi_do_diem_den, kinh_do_diem_den, dia_chi_diem_den, thanh_pho
    });

    return { success: true, message: 'Đặt chuyến xe thành công! Đang tìm tài xế...', data: null };
};

// TODO (TV3): Hoàn thiện logic lấy lịch sử
const getHistory = async (ma_nguoi_dung, thanh_pho) => {
    const query = `SELECT * FROM trips WHERE ma_nguoi_dung = @ma_nguoi_dung ORDER BY ngay_tao DESC`;

    const { result, isReplica } = await executeWithFailover(thanh_pho, query, { ma_nguoi_dung });

    return {
        success: true,
        message: isReplica
            ? 'Lịch sử chuyến đi (dữ liệu từ máy chủ dự phòng).'
            : 'Lấy lịch sử chuyến đi thành công.',
        data: result
    };
};

// TODO (TV3): Hoàn thiện logic cập nhật trạng thái
const updateStatus = async (tripId, trang_thai, thanh_pho) => {
    const validStatuses = ['cho_xu_ly', 'hoan_thanh', 'da_huy'];
    if (!validStatuses.includes(trang_thai)) {
        return { success: false, message: 'Trạng thái không hợp lệ.', data: null };
    }

    const query = `UPDATE trips SET trang_thai = @trang_thai WHERE id = @tripId`;

    await executeWithFailover(thanh_pho, query, { trang_thai, tripId });

    return { success: true, message: `Cập nhật trạng thái chuyến thành "${trang_thai}" thành công.`, data: null };
};

module.exports = { createTrip, getHistory, updateStatus };
