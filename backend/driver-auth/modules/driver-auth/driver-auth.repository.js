const { getPool } = require('../../config/db');

// Cập nhật vị trí tài xế
async function updateDriverLocation({ userId, latitude, longitude, thanh_pho }) {
  const pool = await getPool();

  try {
    const result = await pool.request()
      .input('ma_user', userId)
      .input('vi_do', latitude)
      .input('kinh_do', longitude)
      .input('thanh_pho', thanh_pho)
      .query(`
        UPDATE drivers 
        SET vi_do_hien_tai = @vi_do, 
            kinh_do_hien_tai = @kinh_do
        WHERE ma_user = @ma_user AND thanh_pho = @thanh_pho

        SELECT id, ho_ten, so_dien_thoai, vi_do_hien_tai, kinh_do_hien_tai, 
               is_available, thanh_pho
        FROM drivers
        WHERE ma_user = @ma_user
      `);

    return result.recordset[0] || null;
  } catch (error) {
    throw new Error(`Lỗi cập nhật vị trí: ${error.message}`);
  }
}

// Lấy vị trí hiện tại của tài xế
async function getDriverLocation(driverId) {
  const pool = await getPool();

  try {
    const result = await pool.request()
      .input('driver_id', driverId)
      .query(`
        SELECT id, ho_ten, so_dien_thoai, vi_do_hien_tai, kinh_do_hien_tai, 
               is_available, thanh_pho, tong_so_chuyen
        FROM drivers
        WHERE id = @driver_id
      `);

    return result.recordset[0] || null;
  } catch (error) {
    throw new Error(`Lỗi lấy vị trí: ${error.message}`);
  }
}

// Tính khoảng cách giữa 2 điểm GPS (công thức Haversine)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Bán kính Trái Đất (km)
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);

  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // Khoảng cách tính bằng km
}

// Tìm tài xế gần nhất
async function findNearestDrivers({ 
  latitude, 
  longitude, 
  thanh_pho, 
  loai_dich_vu = null,
  max_distance = 5, // km
  limit = 5 
}) {
  const pool = await getPool();

  try {
    // Lấy danh sách tài xế khả dụng trong thành phố
    const result = await pool.request()
      .input('thanh_pho', thanh_pho)
      .query(`
        SELECT d.id, d.ho_ten, d.so_dien_thoai, d.vi_do_hien_tai, d.kinh_do_hien_tai,
               d.is_available, d.thanh_pho, d.tong_so_chuyen,
               v.loai_xe, v.bien_so, v.hang_xe, v.mau_xe
        FROM drivers d
        LEFT JOIN vehicles v ON d.id = v.ma_tai_xe
        WHERE d.thanh_pho = @thanh_pho 
          AND d.is_available = 1
          AND d.vi_do_hien_tai IS NOT NULL 
          AND d.kinh_do_hien_tai IS NOT NULL
        ORDER BY d.tong_so_chuyen ASC
      `);

    // Tính khoảng cách và lọc những tài xế gần nhất
    const driversWithDistance = result.recordset
      .map(driver => ({
        ...driver,
        distance: calculateDistance(
          latitude,
          longitude,
          driver.vi_do_hien_tai,
          driver.kinh_do_hien_tai
        )
      }))
      .filter(driver => driver.distance <= max_distance)
      .sort((a, b) => a.distance - b.distance)
      .slice(0, limit);

    return driversWithDistance;
  } catch (error) {
    throw new Error(`Lỗi tìm tài xế: ${error.message}`);
  }
}

// Lấy danh sách tài xế khả dụng theo thành phố
async function getAvailableDrivers(thanh_pho) {
  const pool = await getPool();

  try {
    const result = await pool.request()
      .input('thanh_pho', thanh_pho)
      .query(`
        SELECT d.id, d.ho_ten, d.so_dien_thoai, d.vi_do_hien_tai, d.kinh_do_hien_tai,
               d.is_available, d.thanh_pho, d.tong_so_chuyen,
               v.id as vehicle_id, v.loai_xe, v.bien_so, v.hang_xe, v.mau_xe
        FROM drivers d
        LEFT JOIN vehicles v ON d.id = v.ma_tai_xe
        WHERE d.thanh_pho = @thanh_pho AND d.is_available = 1
        ORDER BY d.tong_so_chuyen ASC
      `);

    return result.recordset;
  } catch (error) {
    throw new Error(`Lỗi lấy danh sách tài xế: ${error.message}`);
  }
}

// Cập nhật trạng thái khả dụng của tài xế
async function updateDriverAvailability(driverId, is_available) {
  const pool = await getPool();

  try {
    const result = await pool.request()
      .input('driver_id', driverId)
      .input('is_available', is_available ? 1 : 0)
      .query(`
        UPDATE drivers 
        SET is_available = @is_available
        WHERE id = @driver_id

        SELECT id, ho_ten, is_available, thanh_pho
        FROM drivers
        WHERE id = @driver_id
      `);

    return result.recordset[0] || null;
  } catch (error) {
    throw new Error(`Lỗi cập nhật trạng thái: ${error.message}`);
  }
}

// Lấy thông tin chi tiết tài xế
async function getDriverProfile(driverId) {
  const pool = await getPool();

  try {
    const result = await pool.request()
      .input('driver_id', driverId)
      .query(`
        SELECT d.id, d.ho_ten, d.so_dien_thoai, d.vi_do_hien_tai, d.kinh_do_hien_tai,
               d.is_available, d.thanh_pho, d.tong_so_chuyen, d.ngay_tao,
               u.email, u.vai_tro,
               v.id as vehicle_id, v.loai_xe, v.bien_so, v.hang_xe, v.mau_xe
        FROM drivers d
        LEFT JOIN users u ON d.ma_user = u.id
        LEFT JOIN vehicles v ON d.id = v.ma_tai_xe
        WHERE d.id = @driver_id
      `);

    return result.recordset[0] || null;
  } catch (error) {
    throw new Error(`Lỗi lấy thông tin tài xế: ${error.message}`);
  }
}

module.exports = {
  updateDriverLocation,
  getDriverLocation,
  findNearestDrivers,
  getAvailableDrivers,
  updateDriverAvailability,
  getDriverProfile,
  calculateDistance
};
