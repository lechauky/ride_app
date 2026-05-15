const {
  sql,
  getPrimaryConnection,
  getWritablePrimaryConnection,
  getReplicaConnection,
} = require('../../../config/database');

async function readPrimaryThenReplica(thanh_pho, runQuery) {
  try {
    const primaryPool = await getPrimaryConnection(thanh_pho);
    const primaryResult = await runQuery(primaryPool);
    if (primaryResult.recordset.length > 0) return primaryResult;
  } catch (_) {
    // If Primary is down, fall back to Replica for read-only demo screens.
  }

  const replicaPool = await getReplicaConnection(thanh_pho);
  return await runQuery(replicaPool);
}

function buildListQuery() {
  return `
    SELECT
      id,
      nguoi_nhan,
      tieu_de,
      noi_dung,
      loai,
      da_doc,
      ngay_gui
    FROM notifications
    WHERE nguoi_nhan = @userId
      AND da_xoa = 0
    ORDER BY ngay_gui DESC
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
  `;
}

async function getNotifications({ userId, thanh_pho, limit, offset }) {
  const result = await readPrimaryThenReplica(thanh_pho, (pool) =>
    pool.request()
      .input('userId', sql.UniqueIdentifier, userId)
      .input('limit', sql.Int, limit)
      .input('offset', sql.Int, offset)
      .query(buildListQuery())
  );

  return result.recordset;
}

async function markRead({ notificationId, userId, thanh_pho }) {
  const pool = await getWritablePrimaryConnection(thanh_pho);
  const result = await pool.request()
    .input('id', sql.UniqueIdentifier, notificationId)
    .input('userId', sql.UniqueIdentifier, userId)
    .query(`
      UPDATE notifications
      SET da_doc = 1
      OUTPUT
        INSERTED.id,
        INSERTED.nguoi_nhan,
        INSERTED.tieu_de,
        INSERTED.noi_dung,
        INSERTED.loai,
        INSERTED.da_doc,
        INSERTED.ngay_gui
      WHERE id = @id
        AND nguoi_nhan = @userId
        AND da_xoa = 0
    `);

  return result.recordset[0] || null;
}

async function markAllRead({ userId, thanh_pho }) {
  const pool = await getWritablePrimaryConnection(thanh_pho);
  const result = await pool.request()
    .input('userId', sql.UniqueIdentifier, userId)
    .query(`
      UPDATE notifications
      SET da_doc = 1
      WHERE nguoi_nhan = @userId
        AND da_xoa = 0
        AND da_doc = 0
    `);

  return result.rowsAffected[0] || 0;
}

async function softDelete({ notificationId, userId, thanh_pho }) {
  const pool = await getWritablePrimaryConnection(thanh_pho);
  const result = await pool.request()
    .input('id', sql.UniqueIdentifier, notificationId)
    .input('userId', sql.UniqueIdentifier, userId)
    .query(`
      UPDATE notifications
      SET da_xoa = 1
      WHERE id = @id
        AND nguoi_nhan = @userId
        AND da_xoa = 0
    `);

  return result.rowsAffected[0] || 0;
}

module.exports = {
  getNotifications,
  markRead,
  markAllRead,
  softDelete,
};
