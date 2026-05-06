// ===========================================
// REPOSITORY - Thành viên 1 (Khánh)
// Nhiệm vụ: Tương tác trực tiếp với bảng users
// SỬ DỤNG ĐÚNG logic Định tuyến của Thành viên 4
// ===========================================
const { getPrimaryConnection, getReplicaConnection } = require('../../../config/database');

/**
 * Tìm user theo email (SELECT → dùng Replica để giảm tải)
 * @param {string} email
 * @param {string} thanh_pho - 'HCM' hoặc 'HN'
 */
async function findUserByEmail(email, thanh_pho = 'HCM') {
  const pool = await getReplicaConnection(thanh_pho);
  const result = await pool.request()
    .input('email', email)
    .query('SELECT TOP 1 * FROM users WHERE email = @email');

  return result.recordset[0] || null;
}

async function findUserByEmailPrimary(email, thanh_pho = 'HCM') {
  const pool = await getPrimaryConnection(thanh_pho);
  const result = await pool.request()
    .input('email', email)
    .query('SELECT TOP 1 * FROM users WHERE email = @email');

  return result.recordset[0] || null;
}

/**
 * Tạo user mới (INSERT → dùng Primary bắt buộc)
 * @param {object} userData - { ho_ten, email, mat_khau, so_dien_thoai, thanh_pho }
 */
async function createUser({ ho_ten, email, mat_khau, so_dien_thoai, thanh_pho, vai_tro }) {
  const pool = await getPrimaryConnection(thanh_pho || 'HCM');
  const result = await pool.request()
    .input('ho_ten', ho_ten)
    .input('email', email)
    .input('mat_khau', mat_khau)
    .input('so_dien_thoai', so_dien_thoai || null)
    .input('thanh_pho', thanh_pho || null)
    .input('vai_tro', vai_tro || 'user')
    .query(`
      INSERT INTO users (ho_ten, email, mat_khau, so_dien_thoai, thanh_pho, vai_tro)
      OUTPUT INSERTED.id, INSERTED.ho_ten, INSERTED.email, INSERTED.so_dien_thoai, INSERTED.thanh_pho, INSERTED.vai_tro, INSERTED.ngay_tao
      VALUES (@ho_ten, @email, @mat_khau, @so_dien_thoai, @thanh_pho, @vai_tro)
    `);

  return result.recordset[0];
}

/**
 * Lấy thông tin user theo ID (SELECT → dùng Replica)
 * @param {number} id
 * @param {string} thanh_pho - 'HCM' hoặc 'HN'
 */
async function getUserById(id, thanh_pho = 'HCM') {
  const pool = await getReplicaConnection(thanh_pho);
  const result = await pool.request()
    .input('id', id)
    .query('SELECT id, ho_ten, email, so_dien_thoai, thanh_pho, vai_tro, ngay_tao FROM users WHERE id = @id');

  return result.recordset[0] || null;
}

async function getUserByIdPrimary(id, thanh_pho = 'HCM') {
  const pool = await getPrimaryConnection(thanh_pho);
  const result = await pool.request()
    .input('id', id)
    .query('SELECT id, ho_ten, email, so_dien_thoai, thanh_pho, vai_tro, ngay_tao FROM users WHERE id = @id');

  return result.recordset[0] || null;
}

module.exports = {
  findUserByEmail,
  findUserByEmailPrimary,
  createUser,
  getUserById,
  getUserByIdPrimary,
};
