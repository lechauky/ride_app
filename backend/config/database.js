// ===========================================
// DATA ACCESS & ROUTING LOGIC - Thành viên 4 (Quốc Huy)
// Nhiệm vụ: Quản lý kết nối tới 4 CSDL và Định tuyến Query
// ===========================================
const sql = require('mssql');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

const FAILOVER_RETRY_MS = parseInt(process.env.FAILOVER_RETRY_MS, 10) || 15000;
const READ_ONLY_MESSAGE = 'Hệ thống bảo trì, chỉ xem được lịch sử';
const WRITE_QUERY_REGEX = /^\s*(INSERT|UPDATE|DELETE|MERGE|CREATE|ALTER|DROP|TRUNCATE|EXEC|EXECUTE)\b/i;

const failoverState = {
  HCM: { readOnly: false, lastFailureAt: 0 },
  HN: { readOnly: false, lastFailureAt: 0 }
};

function normalizeCity(thanhPho) {
  if (!thanhPho) return 'HCM';
  return String(thanhPho).trim().toUpperCase();
}

function getFailoverEntry(thanhPho) {
  const city = normalizeCity(thanhPho);
  if (!failoverState[city]) {
    throw new Error('Thành phố không hợp lệ. Phải là HCM hoặc HN.');
  }
  return failoverState[city];
}

function shouldUseReplica(thanhPho) {
  const entry = getFailoverEntry(thanhPho);
  if (!entry.readOnly) return false;
  return Date.now() - entry.lastFailureAt < FAILOVER_RETRY_MS;
}

function isWriteQuery(queryText) {
  if (!queryText) return false;
  return WRITE_QUERY_REGEX.test(String(queryText));
}

function wrapPool(pool) {
  if (pool.__readOnlyWrapped) return pool;
  const originalRequest = pool.request.bind(pool);

  pool.request = function wrappedRequest(...args) {
    const request = originalRequest(...args);
    const originalQuery = request.query.bind(request);

    request.query = async function guardedQuery(queryText, ...rest) {
      if (pool.__readOnly && isWriteQuery(queryText)) {
        const error = new Error(READ_ONLY_MESSAGE);
        error.code = 'READ_ONLY_MODE';
        throw error;
      }
      return originalQuery(queryText, ...rest);
    };

    return request;
  };

  pool.__readOnlyWrapped = true;
  return pool;
}

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
async function getPool(configName, role = 'primary') {
  if (poolCache[configName] && poolCache[configName].connected) {
    return wrapPool(poolCache[configName]);
  }
  const config = dbConfigs[configName];
  if (!config) throw new Error(`Không tìm thấy cấu hình: ${configName}`);

  const pool = new sql.ConnectionPool(config);
  await pool.connect();
  pool.__dbRole = role;
  pool.__readOnly = role === 'replica';
  poolCache[configName] = pool;
  return wrapPool(pool);
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
  const city = normalizeCity(thanhPho);
  if (shouldUseReplica(city)) {
    return await getReplicaConnection(city);
  }

  try {
    if (city === 'HCM') {
      const pool = await getPool('NAM_PRIMARY', 'primary');
      failoverState.HCM = { readOnly: false, lastFailureAt: 0 };
      return pool;
    }
    if (city === 'HN') {
      const pool = await getPool('BAC_PRIMARY', 'primary');
      failoverState.HN = { readOnly: false, lastFailureAt: 0 };
      return pool;
    }
  } catch (error) {
    const entry = getFailoverEntry(city);
    entry.readOnly = true;
    entry.lastFailureAt = Date.now();
    return await getReplicaConnection(city);
  }

  throw new Error('Thành phố không hợp lệ. Phải là HCM hoặc HN.');
}

/**
 * Trỏ tới CSDL Replica (Dùng riêng cho lệnh SELECT để giảm tải)
 * @param {string} thanhPho - 'HCM' hoặc 'HN'
 */
async function getReplicaConnection(thanhPho) {
  const city = normalizeCity(thanhPho);
  if (city === 'HCM') {
    return await getPool('NAM_REPLICA', 'replica');
  }
  if (city === 'HN') {
    return await getPool('BAC_REPLICA', 'replica');
  }
  throw new Error('Thành phố không hợp lệ. Phải là HCM hoặc HN.');
}

// Alias tạm thời để code cũ không bị lỗi (Mặc định gọi HCM)
async function getPoolFallback() {
  return await getPrimaryConnection('HCM');
}

module.exports = {
  sql,
  getPrimaryConnection,
  getReplicaConnection,
  getPool: getPoolFallback,
  READ_ONLY_MESSAGE
};
