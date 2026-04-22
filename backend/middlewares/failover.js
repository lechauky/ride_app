// ===========================================
// MIDDLEWARE FAIL-OVER (Chuyển đổi Primary → Replica)
// Thành viên 5 phụ trách file này
// ===========================================

const sql = require('mssql');
const { getPrimaryConfig, getReplicaConfig } = require('../config/database');

/**
 * Thực thi truy vấn với cơ chế Fail-over
 * - Ưu tiên chạy trên Primary
 * - Nếu Primary lỗi/timeout → tự động chuyển sang Replica
 * - Replica CHỈ cho phép SELECT (Read-Only)
 *
 * @param {string} thanhPho - 'HCM' hoặc 'HN'
 * @param {string} queryString - Câu truy vấn SQL
 * @param {object} params - Tham số truyền vào query (optional)
 * @returns {object} { result, isReplica }
 */
async function executeWithFailover(thanhPho, queryString, params = {}) {
    let pool;

    // === BƯỚC 1: Thử kết nối Primary trước ===
    try {
        const primaryConfig = getPrimaryConfig(thanhPho);
        pool = await sql.connect(primaryConfig);

        const request = pool.request();

        // Gắn các tham số vào câu query
        for (const [key, value] of Object.entries(params)) {
            request.input(key, value);
        }

        const result = await request.query(queryString);
        console.log(`✅ Truy vấn thành công trên PRIMARY (${thanhPho})`);

        return { result: result.recordset, isReplica: false };

    } catch (primaryError) {
        // === BƯỚC 2: Primary lỗi → Chuyển sang Replica ===
        console.log(`⚠️ PRIMARY (${thanhPho}) không phản hồi: ${primaryError.message}`);
        console.log(`🔄 Đang chuyển sang REPLICA (${thanhPho})...`);

        try {
            // *** KIỂM TRA READ-ONLY: Replica CHỈ cho phép SELECT ***
            const queryUpper = queryString.trim().toUpperCase();
            if (queryUpper.startsWith('INSERT') || queryUpper.startsWith('UPDATE') || queryUpper.startsWith('DELETE')) {
                console.log('🚫 Từ chối ghi dữ liệu trên REPLICA - Chế độ Read-Only');
                throw {
                    isReadOnly: true,
                    message: 'Hệ thống đang bảo trì, chỉ có thể xem lịch sử chuyến'
                };
            }

            const replicaConfig = getReplicaConfig(thanhPho);
            pool = await sql.connect(replicaConfig);

            const request = pool.request();
            for (const [key, value] of Object.entries(params)) {
                request.input(key, value);
            }

            const result = await request.query(queryString);
            console.log(`✅ Truy vấn thành công trên REPLICA (${thanhPho}) - Chế độ Read-Only`);

            return { result: result.recordset, isReplica: true };

        } catch (replicaError) {
            // Nếu lỗi Read-Only → ném ra ngoài để Controller xử lý
            if (replicaError.isReadOnly) {
                throw replicaError;
            }

            console.log(`❌ REPLICA (${thanhPho}) cũng không phản hồi: ${replicaError.message}`);
            throw new Error('Không thể kết nối tới bất kỳ máy chủ nào. Vui lòng thử lại sau.');
        }

    } finally {
        // Đóng kết nối
        if (pool) {
            try { await pool.close(); } catch (e) { /* bỏ qua */ }
        }
    }
}

module.exports = { executeWithFailover };
