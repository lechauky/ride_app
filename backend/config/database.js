// ===========================================
// DATABASE CONFIG - Kết nối 4 CSDL Phân Tán
// Thành viên 4 phụ trách file này
// ===========================================

const sql = require('mssql');
require('dotenv').config();

// --- Cấu hình 4 kết nối ---
const dbConfigs = {
    // Miền Nam (HCM) - Primary
    NAM_PRIMARY: {
        server: process.env.DB_NAM_PRIMARY_SERVER,
        port: parseInt(process.env.DB_NAM_PRIMARY_PORT),
        database: process.env.DB_NAM_PRIMARY_DATABASE,
        user: process.env.DB_NAM_PRIMARY_USER,
        password: process.env.DB_NAM_PRIMARY_PASSWORD,
        options: {
            encrypt: false,
            trustServerCertificate: true
        },
        connectionTimeout: 5000,  // 5 giây timeout → quan trọng cho Fail-over
        requestTimeout: 10000
    },

    // Miền Nam (HCM) - Replica (Read-Only)
    NAM_REPLICA: {
        server: process.env.DB_NAM_REPLICA_SERVER,
        port: parseInt(process.env.DB_NAM_REPLICA_PORT),
        database: process.env.DB_NAM_REPLICA_DATABASE,
        user: process.env.DB_NAM_REPLICA_USER,
        password: process.env.DB_NAM_REPLICA_PASSWORD,
        options: {
            encrypt: false,
            trustServerCertificate: true
        },
        connectionTimeout: 5000,
        requestTimeout: 10000
    },

    // Miền Bắc (HN) - Primary
    BAC_PRIMARY: {
        server: process.env.DB_BAC_PRIMARY_SERVER,
        port: parseInt(process.env.DB_BAC_PRIMARY_PORT),
        database: process.env.DB_BAC_PRIMARY_DATABASE,
        user: process.env.DB_BAC_PRIMARY_USER,
        password: process.env.DB_BAC_PRIMARY_PASSWORD,
        options: {
            encrypt: false,
            trustServerCertificate: true
        },
        connectionTimeout: 5000,
        requestTimeout: 10000
    },

    // Miền Bắc (HN) - Replica (Read-Only)
    BAC_REPLICA: {
        server: process.env.DB_BAC_REPLICA_SERVER,
        port: parseInt(process.env.DB_BAC_REPLICA_PORT),
        database: process.env.DB_BAC_REPLICA_DATABASE,
        user: process.env.DB_BAC_REPLICA_USER,
        password: process.env.DB_BAC_REPLICA_PASSWORD,
        options: {
            encrypt: false,
            trustServerCertificate: true
        },
        connectionTimeout: 5000,
        requestTimeout: 10000
    }
};

// =====================================
// HÀM ĐỊNH TUYẾN: Chọn đúng DB theo thành phố
// Thành viên 4 viết logic ở đây
// =====================================

/**
 * Lấy config Primary theo thành phố
 * @param {string} thanhPho - 'HCM' hoặc 'HN'
 */
function getPrimaryConfig(thanhPho) {
    return thanhPho === 'HCM' ? dbConfigs.NAM_PRIMARY : dbConfigs.BAC_PRIMARY;
}

/**
 * Lấy config Replica theo thành phố
 * @param {string} thanhPho - 'HCM' hoặc 'HN'
 */
function getReplicaConfig(thanhPho) {
    return thanhPho === 'HCM' ? dbConfigs.NAM_REPLICA : dbConfigs.BAC_REPLICA;
}

module.exports = {
    dbConfigs,
    getPrimaryConfig,
    getReplicaConfig
};
