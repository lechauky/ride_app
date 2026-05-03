const { getPool, getPrimaryConnection } = require('../../../config/database');

async function findUserByEmail(email) {
  const pool = await getPool();
  const result = await pool.request()
    .input('email', email)
    .query('SELECT TOP 1 * FROM users WHERE email = @email');

  return result.recordset[0] || null;
}

async function createUser({ ho_ten, email, mat_khau, so_dien_thoai, thanh_pho }) {
  const pool = await getPool();
  const result = await pool.request()
    .input('ho_ten', ho_ten)
    .input('email', email)
    .input('mat_khau', mat_khau)
    .input('so_dien_thoai', so_dien_thoai || null)
    .input('thanh_pho', thanh_pho || null)
    .query(`
      INSERT INTO users (ho_ten, email, mat_khau, so_dien_thoai, thanh_pho)
      OUTPUT INSERTED.id, INSERTED.ho_ten, INSERTED.email, INSERTED.so_dien_thoai, INSERTED.thanh_pho, INSERTED.ngay_tao
      VALUES (@ho_ten, @email, @mat_khau, @so_dien_thoai, @thanh_pho)
    `);

  return result.recordset[0];
}

async function getUserById(id) {
  const pool = await getPool();
  const result = await pool.request()
    .input('id', id)
    .query('SELECT id, ho_ten, email, so_dien_thoai, thanh_pho, ngay_tao FROM users WHERE id = @id');

  return result.recordset[0] || null;
}

module.exports = { findUserByEmail, createUser, getUserById };
