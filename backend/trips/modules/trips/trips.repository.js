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

function toNumber(value) {
  if (value === null || value === undefined) return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function calculateDistanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function estimateFare(rideType, distanceKm) {
  const distance = Math.max(toNumber(distanceKm) || 1, 1);
  if (rideType === 'car7') return Math.round(35000 + distance * 15000);
  if (rideType === 'car4') return Math.round(25000 + distance * 11000);
  return Math.round(12000 + distance * 4000);
}

function mapTripRequest(row, latitude, longitude) {
  const pickupLat = toNumber(row.vi_do_diem_don);
  const pickupLon = toNumber(row.kinh_do_diem_don);
  const destinationLat = toNumber(row.vi_do_diem_den);
  const destinationLon = toNumber(row.kinh_do_diem_den);
  const driverDistance = latitude !== null &&
    longitude !== null &&
    pickupLat !== null &&
    pickupLon !== null
      ? Number(calculateDistanceKm(latitude, longitude, pickupLat, pickupLon).toFixed(2))
      : null;

  return {
    ma_chuyen_di: row.ma_chuyen_di || row.id,
    ma_nguoi_dung: row.ma_nguoi_dung,
    ten_khach: row.ten_khach,
    so_dien_thoai: row.so_dien_thoai,
    diem_danh_gia_khach: toNumber(row.diem_danh_gia_khach) || 5,
    ma_loai_dich_vu: row.ma_loai_dich_vu,
    ten_loai_dich_vu: row.ten_loai_dich_vu,
    vi_do_diem_don: pickupLat,
    kinh_do_diem_don: pickupLon,
    dia_chi_diem_don: row.dia_chi_diem_don,
    vi_do_diem_den: destinationLat,
    kinh_do_diem_den: destinationLon,
    dia_chi_diem_den: row.dia_chi_diem_den,
    khoang_cach_km: toNumber(row.khoang_cach_km),
    so_tien: row.so_tien === null || row.so_tien === undefined
      ? estimateFare(row.ma_loai_dich_vu, row.khoang_cach_km)
      : Number(row.so_tien),
    phuong_thuc: row.phuong_thuc || 'tien_mat',
    trang_thai: row.trang_thai,
    thanh_pho: row.thanh_pho,
    ngay_tao: row.ngay_tao,
    khoang_cach_den_tai_xe_km: driverDistance,
  };
}

async function createTrip(payload) {
  const pool = await getPrimaryConnection(payload.thanh_pho);
  const transaction = new sql.Transaction(pool);

  await transaction.begin();
  try {
    const tripResult = await new sql.Request(transaction)
      .input('ma_nguoi_dung', sql.UniqueIdentifier, payload.ma_nguoi_dung)
      .input('ma_loai_dich_vu', sql.VarChar(10), payload.ma_loai_dich_vu)
      .input('vi_do_diem_don', sql.Decimal(10, 8), payload.vi_do_diem_don)
      .input('kinh_do_diem_don', sql.Decimal(11, 8), payload.kinh_do_diem_don)
      .input('dia_chi_diem_don', sql.NVarChar(255), payload.dia_chi_diem_don)
      .input('vi_do_diem_den', sql.Decimal(10, 8), payload.vi_do_diem_den)
      .input('kinh_do_diem_den', sql.Decimal(11, 8), payload.kinh_do_diem_den)
      .input('dia_chi_diem_den', sql.NVarChar(255), payload.dia_chi_diem_den)
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

    const trip = tripResult.recordset[0] || null;

    if (trip && payload.so_tien !== null) {
      await new sql.Request(transaction)
        .input('ma_chuyen_di', sql.UniqueIdentifier, trip.id)
        .input('so_tien', sql.Int, payload.so_tien)
        .input('phuong_thuc', sql.VarChar(20), payload.phuong_thuc)
        .input('trang_thai', sql.VarChar(20), payload.trang_thai_thanh_toan)
        .input('thoi_diem_thanh_toan', sql.DateTime2(0),
          payload.trang_thai_thanh_toan === 'da_thanh_toan' ? new Date() : null)
        .query(`
          INSERT INTO payments (
            ma_chuyen_di,
            so_tien,
            phuong_thuc,
            trang_thai,
            thoi_diem_thanh_toan
          )
          VALUES (
            @ma_chuyen_di,
            @so_tien,
            @phuong_thuc,
            @trang_thai,
            @thoi_diem_thanh_toan
          )
        `);
    }

    await transaction.commit();

    return trip
      ? {
          ...trip,
          so_tien: payload.so_tien,
          phuong_thuc: payload.phuong_thuc,
          trang_thai_thanh_toan: payload.trang_thai_thanh_toan,
        }
      : null;
  } catch (error) {
    await transaction.rollback();
    throw error;
  }
}

async function getTripHistoryByUserId({ userId, thanh_pho, limit, offset }) {
  if (thanh_pho) {
    const readLimit = limit + offset;
    const runHistoryQuery = (pool) =>
      pool.request()
        .input('userId', sql.UniqueIdentifier, userId)
        .input('limit', sql.Int, readLimit)
        .input('offset', sql.Int, 0)
        .query(buildHistoryQuery());

    const results = await Promise.allSettled([
      getPrimaryConnection(thanh_pho).then(runHistoryQuery),
      getReplicaConnection(thanh_pho).then(runHistoryQuery),
    ]);

    const rowsById = new Map();
    for (const result of results) {
      if (result.status !== 'fulfilled') continue;
      for (const row of result.value.recordset) {
        rowsById.set(String(row.id), row);
      }
    }

    return [...rowsById.values()]
      .sort((a, b) => new Date(b.ngay_tao) - new Date(a.ngay_tao))
      .slice(offset, offset + limit);
  }

  const [hcmPool, hnPool] = await Promise.all([
    getPrimaryConnection('HCM'),
    getPrimaryConnection('HN'),
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

async function getNearestPendingTrips({ thanh_pho, limit, latitude, longitude, driverUserId }) {
  const pool = await getPrimaryConnection(thanh_pho);
  let driverId = null;

  if (driverUserId) {
    const driverResult = await pool.request()
      .input('ma_user', sql.UniqueIdentifier, driverUserId)
      .input('thanh_pho', sql.VarChar(10), thanh_pho)
      .query(`
        SELECT TOP (1) id
        FROM drivers
        WHERE ma_user = @ma_user
          AND thanh_pho = @thanh_pho
      `);
    driverId = driverResult.recordset[0]?.id || null;
  }

  const result = await pool.request()
    .input('thanh_pho', sql.VarChar(10), thanh_pho)
    .input('driver_id', sql.UniqueIdentifier, driverId)
    .query(`
      SELECT TOP (50)
        t.id AS ma_chuyen_di,
        t.ma_nguoi_dung,
        u.ho_ten AS ten_khach,
        u.so_dien_thoai,
        CAST(5.0 AS DECIMAL(4,2)) AS diem_danh_gia_khach,
        t.ma_loai_dich_vu,
        rt.ten_loai AS ten_loai_dich_vu,
        t.vi_do_diem_don,
        t.kinh_do_diem_don,
        t.dia_chi_diem_don,
        t.vi_do_diem_den,
        t.kinh_do_diem_den,
        t.dia_chi_diem_den,
        t.khoang_cach_km,
        p.so_tien,
        p.phuong_thuc,
        t.trang_thai,
        t.thanh_pho,
        t.ngay_tao
      FROM trips t
      INNER JOIN users u ON u.id = t.ma_nguoi_dung
      LEFT JOIN ride_types rt ON rt.id = t.ma_loai_dich_vu
      LEFT JOIN payments p ON p.ma_chuyen_di = t.id
      WHERE t.thanh_pho = @thanh_pho
        AND t.trang_thai = 'cho_xu_ly'
        AND (
          @driver_id IS NULL
          OR EXISTS (
            SELECT 1
            FROM vehicles driver_vehicle
            WHERE driver_vehicle.ma_tai_xe = @driver_id
              AND driver_vehicle.dang_hoat_dong = 1
              AND t.ma_loai_dich_vu = CASE driver_vehicle.loai_xe
                WHEN 'xe_may' THEN 'bike'
                WHEN 'o_to_4_cho' THEN 'car4'
                WHEN 'o_to_7_cho' THEN 'car7'
              END
          )
        )
        AND NOT EXISTS (
          SELECT 1
          FROM trip_assignments ta
          WHERE ta.ma_chuyen_di = t.id
            AND (
              ta.trang_thai_nhan IN ('dang_xu_ly', 'da_nhan')
              OR (
                @driver_id IS NOT NULL
                AND ta.ma_tai_xe = @driver_id
                AND ta.trang_thai_nhan = 'tu_choi'
              )
            )
        )
      ORDER BY t.ngay_tao DESC
    `);

  const mapped = result.recordset.map((row) =>
    mapTripRequest(row, latitude, longitude)
  );

  if (latitude !== null && longitude !== null) {
    mapped.sort((a, b) => {
      const distanceA = a.khoang_cach_den_tai_xe_km ?? Number.POSITIVE_INFINITY;
      const distanceB = b.khoang_cach_den_tai_xe_km ?? Number.POSITIVE_INFINITY;
      if (distanceA !== distanceB) return distanceA - distanceB;
      return new Date(b.ngay_tao) - new Date(a.ngay_tao);
    });
  }

  return mapped.slice(0, limit);
}

async function getDriverByUserId(transaction, driverUserId, thanh_pho) {
  const result = await new sql.Request(transaction)
    .input('ma_user', sql.UniqueIdentifier, driverUserId)
    .input('thanh_pho', sql.VarChar(10), thanh_pho)
    .query(`
      SELECT TOP (1)
        d.id,
        d.ma_user,
        d.ho_ten,
        d.so_dien_thoai,
        d.thanh_pho
      FROM drivers d
      WHERE d.ma_user = @ma_user
        AND d.thanh_pho = @thanh_pho
    `);

  return result.recordset[0] || null;
}

async function acceptTrip({ tripId, driverUserId, thanh_pho }) {
  const pool = await getPrimaryConnection(thanh_pho);
  const transaction = new sql.Transaction(pool);

  await transaction.begin();
  try {
    const driver = await getDriverByUserId(transaction, driverUserId, thanh_pho);
    if (!driver) {
      const error = new Error('Không tìm thấy hồ sơ tài xế cho tài khoản này');
      error.code = 'DRIVER_NOT_FOUND';
      throw error;
    }

    const tripResult = await new sql.Request(transaction)
      .input('tripId', sql.UniqueIdentifier, tripId)
      .input('thanh_pho', sql.VarChar(10), thanh_pho)
      .input('driverId', sql.UniqueIdentifier, driver.id)
      .query(`
        SELECT TOP (1)
          id,
          trang_thai,
          CASE WHEN EXISTS (
            SELECT 1
            FROM vehicles v
            WHERE v.ma_tai_xe = @driverId
              AND v.dang_hoat_dong = 1
              AND trips.ma_loai_dich_vu = CASE v.loai_xe
                WHEN 'xe_may' THEN 'bike'
                WHEN 'o_to_4_cho' THEN 'car4'
                WHEN 'o_to_7_cho' THEN 'car7'
              END
          ) THEN 1 ELSE 0 END AS can_accept
        FROM trips WITH (UPDLOCK, ROWLOCK)
        WHERE id = @tripId
          AND thanh_pho = @thanh_pho
      `);

    const trip = tripResult.recordset[0] || null;
    if (!trip) {
      const error = new Error('Không tìm thấy chuyến đi');
      error.code = 'TRIP_NOT_FOUND';
      throw error;
    }

    if (trip.trang_thai !== 'cho_xu_ly') {
      const error = new Error('Chuyến đi không còn ở trạng thái chờ xử lý');
      error.code = 'TRIP_NOT_AVAILABLE';
      throw error;
    }

    if (trip.can_accept !== 1) {
      const error = new Error('Loại xe của tài xế không phù hợp chuyến này');
      error.code = 'VEHICLE_TYPE_MISMATCH';
      throw error;
    }

    await new sql.Request(transaction)
      .input('ma_chuyen_di', sql.UniqueIdentifier, tripId)
      .input('ma_tai_xe', sql.UniqueIdentifier, driver.id)
      .query(`
        INSERT INTO trip_assignments (ma_chuyen_di, ma_tai_xe, trang_thai_nhan)
        VALUES (@ma_chuyen_di, @ma_tai_xe, 'da_nhan')
      `);

    await new sql.Request(transaction)
      .input('tripId', sql.UniqueIdentifier, tripId)
      .query(`
        UPDATE trips
        SET trang_thai = 'dang_don'
        WHERE id = @tripId
      `);

    await new sql.Request(transaction)
      .input('driverId', sql.UniqueIdentifier, driver.id)
      .query(`
        UPDATE drivers
        SET is_available = 0
        WHERE id = @driverId
      `);

    await transaction.commit();

    return {
      ma_chuyen_di: tripId,
      ma_tai_xe: driver.id,
      trang_thai: 'dang_don',
      trang_thai_nhan: 'da_nhan',
    };
  } catch (error) {
    await transaction.rollback();
    throw error;
  }
}

async function rejectTrip({ tripId, driverUserId, thanh_pho }) {
  const pool = await getPrimaryConnection(thanh_pho);
  const transaction = new sql.Transaction(pool);

  await transaction.begin();
  try {
    const driver = await getDriverByUserId(transaction, driverUserId, thanh_pho);
    if (!driver) {
      const error = new Error('Không tìm thấy hồ sơ tài xế cho tài khoản này');
      error.code = 'DRIVER_NOT_FOUND';
      throw error;
    }

    const rejectResult = await new sql.Request(transaction)
      .input('ma_chuyen_di', sql.UniqueIdentifier, tripId)
      .input('ma_tai_xe', sql.UniqueIdentifier, driver.id)
      .query(`
        IF EXISTS (
          SELECT 1
          FROM trips
          WHERE id = @ma_chuyen_di
            AND trang_thai = 'cho_xu_ly'
        )
        AND NOT EXISTS (
          SELECT 1
          FROM trip_assignments
          WHERE ma_chuyen_di = @ma_chuyen_di
            AND ma_tai_xe = @ma_tai_xe
            AND trang_thai_nhan = 'tu_choi'
        )
        BEGIN
          INSERT INTO trip_assignments (ma_chuyen_di, ma_tai_xe, trang_thai_nhan)
          VALUES (@ma_chuyen_di, @ma_tai_xe, 'tu_choi')
        END
      `);

    if (!rejectResult.rowsAffected || rejectResult.rowsAffected[0] === 0) {
      const error = new Error('Chuyến đi không còn ở trạng thái chờ xử lý hoặc đã từ chối trước đó');
      error.code = 'TRIP_NOT_AVAILABLE';
      throw error;
    }

    await transaction.commit();

    return {
      ma_chuyen_di: tripId,
      ma_tai_xe: driver.id,
      trang_thai_nhan: 'tu_choi',
    };
  } catch (error) {
    await transaction.rollback();
    throw error;
  }
}

async function completeTrip({ tripId, driverUserId, thanh_pho }) {
  const pool = await getPrimaryConnection(thanh_pho);
  const transaction = new sql.Transaction(pool);

  await transaction.begin();
  try {
    const driver = await getDriverByUserId(transaction, driverUserId, thanh_pho);
    if (!driver) {
      const error = new Error('Không tìm thấy hồ sơ tài xế cho tài khoản này');
      error.code = 'DRIVER_NOT_FOUND';
      throw error;
    }

    const completeResult = await new sql.Request(transaction)
      .input('tripId', sql.UniqueIdentifier, tripId)
      .input('driverId', sql.UniqueIdentifier, driver.id)
      .query(`
        UPDATE trips
        SET trang_thai = 'hoan_thanh'
        WHERE id = @tripId
          AND trang_thai IN ('dang_don', 'dang_cho')
          AND EXISTS (
            SELECT 1
            FROM trip_assignments
            WHERE ma_chuyen_di = @tripId
              AND ma_tai_xe = @driverId
              AND trang_thai_nhan = 'da_nhan'
          )
      `);

    if (!completeResult.rowsAffected || completeResult.rowsAffected[0] === 0) {
      const error = new Error('Chuyến đi không thuộc tài xế này hoặc chưa ở trạng thái có thể hoàn thành');
      error.code = 'TRIP_NOT_AVAILABLE';
      throw error;
    }

    await new sql.Request(transaction)
      .input('tripId', sql.UniqueIdentifier, tripId)
      .input('driverId', sql.UniqueIdentifier, driver.id)
      .query(`
        UPDATE trip_assignments
        SET thoi_diem_hoan_thanh = SYSDATETIME()
        WHERE ma_chuyen_di = @tripId
          AND ma_tai_xe = @driverId
          AND trang_thai_nhan = 'da_nhan'

        UPDATE drivers
        SET is_available = 1,
            tong_so_chuyen = tong_so_chuyen + 1
        WHERE id = @driverId
      `);

    await transaction.commit();

    return {
      ma_chuyen_di: tripId,
      ma_tai_xe: driver.id,
      trang_thai: 'hoan_thanh',
    };
  } catch (error) {
    await transaction.rollback();
    throw error;
  }
}

async function saveRating({
  tripId,
  nguoi_danh_gia,
  loai_nguoi_danh_gia,
  diem_so,
  tags_nhan_xet,
  nhan_xet,
  thanh_pho,
}) {
  const pool = await getPrimaryConnection(thanh_pho);
  const result = await pool.request()
    .input('ma_chuyen_di', sql.UniqueIdentifier, tripId)
    .input('nguoi_danh_gia', sql.UniqueIdentifier, nguoi_danh_gia)
    .input('loai_nguoi_danh_gia', sql.VarChar(10), loai_nguoi_danh_gia)
    .input('diem_so', sql.SmallInt, diem_so)
    .input('tags_nhan_xet', sql.NVarChar(sql.MAX), tags_nhan_xet)
    .input('nhan_xet', sql.NVarChar(250), nhan_xet)
    .query(`
      IF EXISTS (
        SELECT 1
        FROM ratings
        WHERE ma_chuyen_di = @ma_chuyen_di
          AND loai_nguoi_danh_gia = @loai_nguoi_danh_gia
      )
      BEGIN
        UPDATE ratings
        SET nguoi_danh_gia = @nguoi_danh_gia,
            diem_so = @diem_so,
            tags_nhan_xet = @tags_nhan_xet,
            nhan_xet = @nhan_xet,
            ngay_danh_gia = SYSDATETIME()
        WHERE ma_chuyen_di = @ma_chuyen_di
          AND loai_nguoi_danh_gia = @loai_nguoi_danh_gia
      END
      ELSE
      BEGIN
        INSERT INTO ratings (
          ma_chuyen_di,
          nguoi_danh_gia,
          loai_nguoi_danh_gia,
          diem_so,
          tags_nhan_xet,
          nhan_xet
        )
        VALUES (
          @ma_chuyen_di,
          @nguoi_danh_gia,
          @loai_nguoi_danh_gia,
          @diem_so,
          @tags_nhan_xet,
          @nhan_xet
        )
      END

      SELECT TOP (1)
        id,
        ma_chuyen_di,
        nguoi_danh_gia,
        loai_nguoi_danh_gia,
        diem_so,
        tags_nhan_xet,
        nhan_xet,
        ngay_danh_gia
      FROM ratings
      WHERE ma_chuyen_di = @ma_chuyen_di
        AND loai_nguoi_danh_gia = @loai_nguoi_danh_gia
      ORDER BY ngay_danh_gia DESC
    `);

  return result.recordset[0] || null;
}

module.exports = {
  createTrip,
  getTripHistoryByUserId,
  getNearestPendingTrips,
  acceptTrip,
  rejectTrip,
  completeTrip,
  saveRating,
};
