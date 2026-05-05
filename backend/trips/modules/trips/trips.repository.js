const { sql, getPrimaryConnection, getReplicaConnection } = require('../../../config/database');

function buildHistoryQuery() {
  return `
    SELECT
      id,
      ma_nguoi_dung,
      ma_loai_dich_vu,
      vi_do_diem_don,
      kinh_do_diem_don,
      dia_chi_diem_don,
      vi_do_diem_den,
      kinh_do_diem_den,
      dia_chi_diem_den,
      khoang_cach_km,
      trang_thai,
      thanh_pho,
      ngay_tao
    FROM trips
    WHERE ma_nguoi_dung = @userId
    ORDER BY ngay_tao DESC
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
  `;
}

async function createTrip(payload) {
  const pool = await getPrimaryConnection(payload.thanh_pho);
  const result = await pool.request()
    .input('ma_nguoi_dung', sql.UniqueIdentifier, payload.ma_nguoi_dung)
    .input('ma_loai_dich_vu', sql.VarChar(10), payload.ma_loai_dich_vu)
    .input('vi_do_diem_don', sql.Decimal(10, 8), payload.vi_do_diem_don)
    .input('kinh_do_diem_don', sql.Decimal(11, 8), payload.kinh_do_diem_don)
    .input('dia_chi_diem_don', sql.VarChar(255), payload.dia_chi_diem_don)
    .input('vi_do_diem_den', sql.Decimal(10, 8), payload.vi_do_diem_den)
    .input('kinh_do_diem_den', sql.Decimal(11, 8), payload.kinh_do_diem_den)
    .input('dia_chi_diem_den', sql.VarChar(255), payload.dia_chi_diem_den)
    .input('khoang_cach_km', sql.Decimal(6, 2), payload.khoang_cach_km)
    .input('trang_thai', sql.VarChar(20), payload.trang_thai)
    .input('thanh_pho', sql.VarChar(10), payload.thanh_pho)
    .query(`
      INSERT INTO trips (
        ma_nguoi_dung,
        ma_loai_dich_vu,
        vi_do_diem_don,
        kinh_do_diem_don,
        dia_chi_diem_don,
        vi_do_diem_den,
        kinh_do_diem_den,
        dia_chi_diem_den,
        khoang_cach_km,
        trang_thai,
        thanh_pho
      )
      OUTPUT
        INSERTED.id,
        INSERTED.ma_nguoi_dung,
        INSERTED.ma_loai_dich_vu,
        INSERTED.vi_do_diem_don,
        INSERTED.kinh_do_diem_don,
        INSERTED.dia_chi_diem_don,
        INSERTED.vi_do_diem_den,
        INSERTED.kinh_do_diem_den,
        INSERTED.dia_chi_diem_den,
        INSERTED.khoang_cach_km,
        INSERTED.trang_thai,
        INSERTED.thanh_pho,
        INSERTED.ngay_tao
      VALUES (
        @ma_nguoi_dung,
        @ma_loai_dich_vu,
        @vi_do_diem_don,
        @kinh_do_diem_don,
        @dia_chi_diem_don,
        @vi_do_diem_den,
        @kinh_do_diem_den,
        @dia_chi_diem_den,
        COALESCE(@khoang_cach_km, 1.0),
        @trang_thai,
        @thanh_pho
      )
    `);

  return result.recordset[0] || null;
}

async function getTripHistoryByUserId({ userId, thanh_pho, limit, offset }) {
  if (thanh_pho) {
    const pool = await getReplicaConnection(thanh_pho);
    const result = await pool.request()
      .input('userId', sql.UniqueIdentifier, userId)
      .input('limit', sql.Int, limit)
      .input('offset', sql.Int, offset)
      .query(buildHistoryQuery());

    return result.recordset;
  }

  const [hcmPool, hnPool] = await Promise.all([
    getReplicaConnection('HCM'),
    getReplicaConnection('HN'),
  ]);

  const [hcmResult, hnResult] = await Promise.all([
    hcmPool.request()
      .input('userId', sql.UniqueIdentifier, userId)
      .input('limit', sql.Int, limit)
      .input('offset', sql.Int, 0)
      .query(buildHistoryQuery()),
    hnPool.request()
      .input('userId', sql.UniqueIdentifier, userId)
      .input('limit', sql.Int, limit)
      .input('offset', sql.Int, 0)
      .query(buildHistoryQuery()),
  ]);

  const merged = [...hcmResult.recordset, ...hnResult.recordset]
    .sort((a, b) => new Date(b.ngay_tao) - new Date(a.ngay_tao))
    .slice(offset, offset + limit);

  return merged;
}

module.exports = {
  createTrip,
  getTripHistoryByUserId,
};
