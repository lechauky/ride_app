// ===========================================
// SERVICE - Thành viên 2 (Đức Huy)
// Nhiệm vụ: Xử lý logic nghiệp vụ Tài xế
// Truyền thanh_pho xuống Repository để Định tuyến DB
// ===========================================
const repository = require('./driver-auth.repository');

// Cập nhật vị trí tài xế
async function updateLocation(locationData) {
  const { userId, latitude, longitude, thanh_pho } = locationData;

  if (!userId || latitude === undefined || longitude === undefined) {
    throw new Error('Thiếu thông tin vị trí: userId, latitude, longitude');
  }

  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    throw new Error('Vị trí không hợp lệ');
  }

  // UPDATE → Primary (truyền thanh_pho để định tuyến đúng DB)
  const driver = await repository.updateDriverLocation({
    userId,
    latitude: parseFloat(latitude),
    longitude: parseFloat(longitude),
    thanh_pho: thanh_pho || 'HCM'
  });

  if (!driver) {
    throw new Error('Không tìm thấy tài xế');
  }

  return {
    success: true,
    message: 'Cập nhật vị trí thành công',
    data: {
      id: driver.id,
      ho_ten: driver.ho_ten,
      vi_do: driver.vi_do_hien_tai,
      kinh_do: driver.kinh_do_hien_tai,
      is_available: driver.is_available === 1,
      thanh_pho: driver.thanh_pho
    }
  };
}

// Tìm tài xế gần nhất (SELECT → Replica qua repository)
async function findNearestDrivers(searchData) {
  const {
    latitude,
    longitude,
    thanh_pho,
    loai_dich_vu = null,
    max_distance = 5,
    limit = 5
  } = searchData;

  if (!latitude || !longitude || !thanh_pho) {
    throw new Error('Thiếu thông tin tìm kiếm: latitude, longitude, thanh_pho');
  }

  const drivers = await repository.findNearestDrivers({
    latitude: parseFloat(latitude),
    longitude: parseFloat(longitude),
    thanh_pho,
    loai_dich_vu,
    max_distance: parseFloat(max_distance),
    limit: parseInt(limit)
  });

  if (drivers.length === 0) {
    return {
      success: true,
      message: 'Không có tài xế khả dụng gần đây',
      data: []
    };
  }

  return {
    success: true,
    message: `Tìm thấy ${drivers.length} tài xế gần nhất`,
    data: drivers.map(driver => ({
      id: driver.id,
      ho_ten: driver.ho_ten,
      so_dien_thoai: driver.so_dien_thoai,
      vi_do: driver.vi_do_hien_tai,
      kinh_do: driver.kinh_do_hien_tai,
      is_available: driver.is_available === 1,
      thanh_pho: driver.thanh_pho,
      distance: driver.distance.toFixed(2), // km
      tong_so_chuyen: driver.tong_so_chuyen,
      vehicle: driver.loai_xe ? {
        loai_xe: driver.loai_xe,
        bien_so: driver.bien_so,
        hang_xe: driver.hang_xe,
        mau_xe: driver.mau_xe
      } : null
    }))
  };
}

// Lấy danh sách tài xế khả dụng (SELECT → Replica qua repository)
async function getAvailableDriversList(thanh_pho) {
  if (!thanh_pho) {
    throw new Error('Thiếu thông tin thành phố');
  }

  const drivers = await repository.getAvailableDrivers(thanh_pho);

  return {
    success: true,
    message: `Có ${drivers.length} tài xế khả dụng`,
    data: drivers.map(driver => ({
      id: driver.id,
      ho_ten: driver.ho_ten,
      so_dien_thoai: driver.so_dien_thoai,
      vi_do: driver.vi_do_hien_tai,
      kinh_do: driver.kinh_do_hien_tai,
      is_available: driver.is_available === 1,
      thanh_pho: driver.thanh_pho,
      tong_so_chuyen: driver.tong_so_chuyen,
      vehicle: driver.vehicle_id ? {
        id: driver.vehicle_id,
        loai_xe: driver.loai_xe,
        bien_so: driver.bien_so,
        hang_xe: driver.hang_xe,
        mau_xe: driver.mau_xe
      } : null
    }))
  };
}

// Cập nhật trạng thái khả dụng (UPDATE → Primary qua repository)
async function updateAvailability(driverId, is_available, thanh_pho = 'HCM') {
  if (!driverId) {
    throw new Error('Thiếu ID tài xế');
  }

  const driver = await repository.updateDriverAvailability(driverId, is_available, thanh_pho);

  if (!driver) {
    throw new Error('Không tìm thấy tài xế');
  }

  return {
    success: true,
    message: `Cập nhật trạng thái thành công`,
    data: {
      id: driver.id,
      ho_ten: driver.ho_ten,
      is_available: driver.is_available === 1,
      thanh_pho: driver.thanh_pho
    }
  };
}

async function updateAvailabilityByUser(userId, is_available, thanh_pho = 'HCM') {
  if (!userId) {
    throw new Error('Thiếu ID tài khoản tài xế');
  }

  const driver = await repository.updateDriverAvailabilityByUser(userId, is_available, thanh_pho);

  if (!driver) {
    throw new Error('Không tìm thấy tài xế');
  }

  return {
    success: true,
    message: 'Cập nhật trạng thái thành công',
    data: {
      id: driver.id,
      ho_ten: driver.ho_ten,
      is_available: driver.is_available === 1 || driver.is_available === true,
      thanh_pho: driver.thanh_pho
    }
  };
}

// Lấy thông tin chi tiết tài xế (SELECT → Replica qua repository)
async function getProfile(driverId, thanh_pho = 'HCM') {
  if (!driverId) {
    throw new Error('Thiếu ID tài xế');
  }

  const driver = await repository.getDriverProfile(driverId, thanh_pho);

  if (!driver) {
    throw new Error('Không tìm thấy tài xế');
  }

  return mapProfile(driver);
}

function mapProfile(driver) {
  return {
    success: true,
    message: 'Lấy thông tin tài xế thành công',
    data: {
      id: driver.id,
      ho_ten: driver.ho_ten,
      so_dien_thoai: driver.so_dien_thoai,
      email: driver.email,
      vai_tro: driver.vai_tro,
      vi_do: driver.vi_do_hien_tai,
      kinh_do: driver.kinh_do_hien_tai,
      is_available: driver.is_available === 1,
      thanh_pho: driver.thanh_pho,
      tong_so_chuyen: driver.tong_so_chuyen,
      ngay_tao: driver.ngay_tao,
      vehicle: driver.vehicle_id ? {
        id: driver.vehicle_id,
        loai_xe: driver.loai_xe,
        bien_so: driver.bien_so,
        hang_xe: driver.hang_xe,
        mau_xe: driver.mau_xe,
        nam_san_xuat: driver.nam_san_xuat
      } : null
    }
  };
}

async function getProfileByUser(userId, thanh_pho = 'HCM') {
  if (!userId) {
    throw new Error('Thiếu ID tài khoản tài xế');
  }

  const driver = await repository.getDriverProfileByUserId(userId, thanh_pho);

  if (!driver) {
    throw new Error('Không tìm thấy tài xế');
  }

  return mapProfile(driver);
}

async function saveVehicle(userId, payload) {
  if (!userId) {
    throw new Error('Thiếu ID tài khoản tài xế');
  }

  const thanh_pho = payload.thanh_pho || 'HCM';
  const loai_xe = String(payload.loai_xe || '').trim();
  const bien_so = String(payload.bien_so || '').trim().toUpperCase();
  const hang_xe = String(payload.hang_xe || '').trim();
  const mau_xe = String(payload.mau_xe || '').trim();
  const nam_san_xuat = payload.nam_san_xuat === undefined || payload.nam_san_xuat === null || payload.nam_san_xuat === ''
    ? null
    : parseInt(payload.nam_san_xuat, 10);

  if (!['xe_may', 'o_to_4_cho', 'o_to_7_cho'].includes(loai_xe)) {
    throw new Error('loai_xe không hợp lệ');
  }
  if (!bien_so || !hang_xe || !mau_xe) {
    throw new Error('Thiếu thông tin xe');
  }
  if (nam_san_xuat !== null) {
    const year = new Date().getFullYear();
    if (!Number.isInteger(nam_san_xuat) || nam_san_xuat < 1980 || nam_san_xuat > year) {
      throw new Error(`nam_san_xuat phải từ 1980 đến ${year}`);
    }
  }

  const driver = await repository.upsertDriverVehicle({
    userId,
    thanh_pho,
    loai_xe,
    bien_so,
    hang_xe,
    mau_xe,
    nam_san_xuat,
    dang_hoat_dong: payload.dang_hoat_dong !== false,
  });

  return {
    success: true,
    message: 'Lưu thông tin xe thành công',
    data: {
      id: driver.id,
      ho_ten: driver.ho_ten,
      is_available: driver.is_available === 1 || driver.is_available === true,
      thanh_pho: driver.thanh_pho,
      vehicle: {
        id: driver.vehicle_id,
        loai_xe: driver.loai_xe,
        bien_so: driver.bien_so,
        hang_xe: driver.hang_xe,
        mau_xe: driver.mau_xe,
        nam_san_xuat: driver.nam_san_xuat,
        dang_hoat_dong: driver.dang_hoat_dong === 1 || driver.dang_hoat_dong === true,
      }
    }
  };
}

module.exports = {
  updateLocation,
  findNearestDrivers,
  getAvailableDriversList,
  updateAvailability,
  updateAvailabilityByUser,
  getProfile,
  getProfileByUser,
  saveVehicle
};
