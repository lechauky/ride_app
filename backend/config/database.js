// ===========================================
// DATA ACCESS & ROUTING LOGIC - Thành viên 4 (Quốc Huy)
// Nhiệm vụ: Quản lý kết nối tới 4 CSDL và Định tuyến Query
// ===========================================
const sql = require('mssql');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

// 1. Nhận 4 chuỗi kết nối từ file .env
const envPath = path.resolve(__dirname, '../.env');
const envConfig = dotenv.parse(fs.readFileSync(envPath));

function buildConfig(prefix) {
  return {
    server: envConfig[`${prefix}_SERVER`] || 'localhost',
    port: parseInt(envConfig[`${prefix}_PORT`]) || 1433,
    database: envConfig[`${prefix}_DATABASE`],
    user: envConfig[`${prefix}_USER`],
    password: envConfig[`${prefix}_PASSWORD`],
    options: {
      encrypt: false,
      trustServerCertificate: true,
      enableArithAbort: true
    },
    pool: { max: 10, min: 0, idleTimeoutMillis: 30000 }
  };
}

const dbConfigs = {
  NAM_PRIMARY: buildConfig('DB_NAM_PRIMARY'),
  NAM_REPLICA: buildConfig('DB_NAM_REPLICA'),
  BAC_PRIMARY: buildConfig('DB_BAC_PRIMARY'),
  BAC_REPLICA: buildConfig('DB_BAC_REPLICA')
};

const poolCache = {};

// Hàm tiện ích để mở connection pool
async function getPool(configName) {
  if (poolCache[configName] && poolCache[configName].connected) {
    return poolCache[configName];
  }
  const config = dbConfigs[configName];
  if (!config) throw new Error(`Không tìm thấy cấu hình: ${configName}`);
  
  const pool = new sql.ConnectionPool(config);
  await pool.connect();
  poolCache[configName] = pool;
  return pool;
}

// ===========================================
// 2. LOGIC ĐỊNH TUYẾN QUERY (ROUTING LOGIC)
// Phân tích Request (VD: thanh_pho = HCM) để trỏ connection
// tới đúng CSDL miền Nam hoặc miền Bắc.
// ===========================================

/**
 * Trỏ tới CSDL Primary (Dùng cho lệnh INSERT, UPDATE, DELETE)
 * @param {string} thanhPho - 'HCM' hoặc 'HN'
 */
async function getPrimaryConnection(thanhPho) {
  if (thanhPho === 'HCM') {
    return await getPool('NAM_PRIMARY');
  } else if (thanhPho === 'HN') {
    return await getPool('BAC_PRIMARY');
  } else {
    throw new Error('Thành phố không hợp lệ. Phải là HCM hoặc HN.');
  }
}

/**
 * Trỏ tới CSDL Replica (Dùng riêng cho lệnh SELECT để giảm tải)
 * @param {string} thanhPho - 'HCM' hoặc 'HN'
 */
async function getReplicaConnection(thanhPho) {
  if (thanhPho === 'HCM') {
    return await getPool('NAM_REPLICA');
  } else if (thanhPho === 'HN') {
    return await getPool('BAC_REPLICA');
  } else {
    throw new Error('Thành phố không hợp lệ. Phải là HCM hoặc HN.');
  }
}

module.exports = {
  sql,
  getPrimaryConnection,
  getReplicaConnection
};
