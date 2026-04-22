// ===========================================
// SERVICE - TÀI XẾ (Driver)
// Thành viên 2 phụ trách hoàn thiện file này
// TV2: Viết logic cập nhật GPS, tìm tài xế gần nhất
// ===========================================

const { executeWithFailover } = require('../middlewares/failover');

// TODO (TV2): Hoàn thiện logic cập nhật vị trí
const updateLocation = async ({ driver_id, vi_do, kinh_do, thanh_pho }) => {
    const query = `UPDATE drivers
                 SET vi_do_hien_tai = @vi_do, kinh_do_hien_tai = @kinh_do
                 WHERE id = @driver_id`;

    await executeWithFailover(thanh_pho, query, { driver_id, vi_do, kinh_do });

    return { success: true, message: 'Cập nhật vị trí tài xế thành công.', data: null };
};

// TODO (TV2): Hoàn thiện logic tìm tài xế gần nhất
const findNearby = async ({ vi_do, kinh_do, thanh_pho }) => {
    // Tính khoảng cách đơn giản bằng công thức Haversine hoặc so sánh tọa độ
    const query = `SELECT TOP 5 id, ho_ten, so_dien_thoai, vi_do_hien_tai, kinh_do_hien_tai,
                   ABS(vi_do_hien_tai - @vi_do) + ABS(kinh_do_hien_tai - @kinh_do) AS khoang_cach
                 FROM drivers
                 WHERE thanh_pho = @thanh_pho
                 ORDER BY khoang_cach ASC`;

    const { result, isReplica } = await executeWithFailover(thanh_pho, query, { vi_do, kinh_do, thanh_pho });

    return {
        success: true,
        message: isReplica ? 'Dữ liệu từ máy chủ dự phòng (có thể không mới nhất).' : 'Tìm tài xế thành công.',
        data: result
    };
};

module.exports = { updateLocation, findNearby };
