function normalizeCity(city) {
  if (!city) return null;
  const value = String(city).trim().toUpperCase();
  return value === 'HCM' || value === 'HN' ? value : null;
}

function normalizeRideType(value) {
  if (!value) return null;
  const rideType = String(value).trim();
  return ['bike', 'car4', 'car7'].includes(rideType) ? rideType : null;
}

function normalizePaymentMethod(value) {
  if (!value) return null;
  const method = String(value).trim();
  return ['tien_mat', 'vi_dien_tu', 'the_ngan_hang'].includes(method) ? method : null;
}

function isValidLatitude(value) {
  const number = Number(value);
  return Number.isFinite(number) && number >= -90 && number <= 90;
}

function isValidLongitude(value) {
  const number = Number(value);
  return Number.isFinite(number) && number >= -180 && number <= 180;
}

function validateCreateTripPayload(payload) {
  const errors = [];
  const body = payload || {};

  if (!body.ma_nguoi_dung || !String(body.ma_nguoi_dung).trim()) {
    errors.push('ma_nguoi_dung là bắt buộc');
  }

  const ma_loai_dich_vu = normalizeRideType(body.ma_loai_dich_vu);
  if (!ma_loai_dich_vu) {
    errors.push('ma_loai_dich_vu chỉ được là bike, car4 hoặc car7');
  }

  const thanh_pho = normalizeCity(body.thanh_pho);
  if (!thanh_pho) {
    errors.push('thanh_pho chỉ được là HCM hoặc HN');
  }

  if (!isValidLatitude(body.vi_do_diem_don)) errors.push('vi_do_diem_don không hợp lệ');
  if (!isValidLongitude(body.kinh_do_diem_don)) errors.push('kinh_do_diem_don không hợp lệ');
  if (!isValidLatitude(body.vi_do_diem_den)) errors.push('vi_do_diem_den không hợp lệ');
  if (!isValidLongitude(body.kinh_do_diem_den)) errors.push('kinh_do_diem_den không hợp lệ');

  const khoang_cach_km = body.khoang_cach_km === undefined || body.khoang_cach_km === null
    ? null
    : Number(body.khoang_cach_km);
  if (khoang_cach_km !== null && (!Number.isFinite(khoang_cach_km) || khoang_cach_km <= 0)) {
    errors.push('khoang_cach_km phải lớn hơn 0');
  }

  const so_tien = body.so_tien === undefined || body.so_tien === null
    ? null
    : Number(body.so_tien);
  if (so_tien !== null && (!Number.isInteger(so_tien) || so_tien < 0)) {
    errors.push('so_tien phải là số nguyên >= 0');
  }

  const phuong_thuc = normalizePaymentMethod(body.phuong_thuc);
  if (body.phuong_thuc && !phuong_thuc) {
    errors.push('phuong_thuc không hợp lệ');
  }

  return {
    valid: errors.length === 0,
    errors,
    normalized: {
      ma_nguoi_dung: body.ma_nguoi_dung ? String(body.ma_nguoi_dung).trim() : null,
      ma_loai_dich_vu,
      vi_do_diem_don: Number(body.vi_do_diem_don),
      kinh_do_diem_don: Number(body.kinh_do_diem_don),
      vi_do_diem_den: Number(body.vi_do_diem_den),
      kinh_do_diem_den: Number(body.kinh_do_diem_den),
      dia_chi_diem_don: body.dia_chi_diem_don ? String(body.dia_chi_diem_don).trim() : null,
      dia_chi_diem_den: body.dia_chi_diem_den ? String(body.dia_chi_diem_den).trim() : null,
      khoang_cach_km,
      so_tien,
      phuong_thuc: phuong_thuc || 'tien_mat',
      trang_thai_thanh_toan: body.trang_thai_thanh_toan
        ? String(body.trang_thai_thanh_toan).trim()
        : 'cho_thanh_toan',
      thanh_pho,
      trang_thai: body.trang_thai ? String(body.trang_thai).trim() : 'cho_xu_ly',
    },
  };
}

function validatePendingTripsParams(query) {
  const errors = [];
  const body = query || {};
  const thanh_pho = normalizeCity(body.thanh_pho);
  const limit = body.limit ? Number(body.limit) : 1;
  const latitude = body.latitude === undefined || body.latitude === null || body.latitude === ''
    ? null
    : Number(body.latitude);
  const longitude = body.longitude === undefined || body.longitude === null || body.longitude === ''
    ? null
    : Number(body.longitude);

  if (!thanh_pho) {
    errors.push('thanh_pho chỉ được là HCM hoặc HN');
  }

  if (!Number.isInteger(limit) || limit <= 0 || limit > 20) {
    errors.push('limit phải là số nguyên từ 1 đến 20');
  }

  if (latitude !== null && !isValidLatitude(latitude)) errors.push('latitude không hợp lệ');
  if (longitude !== null && !isValidLongitude(longitude)) errors.push('longitude không hợp lệ');

  return {
    valid: errors.length === 0,
    errors,
    normalized: { thanh_pho, limit, latitude, longitude },
  };
}

function validateTripActionPayload(tripId, user, body) {
  const errors = [];
  const thanh_pho = normalizeCity(body?.thanh_pho || user?.thanh_pho);

  if (!tripId || !String(tripId).trim()) {
    errors.push('tripId là bắt buộc');
  }

  if (!user?.id) {
    errors.push('Thiếu thông tin tài xế');
  }

  if (!thanh_pho) {
    errors.push('thanh_pho chỉ được là HCM hoặc HN');
  }

  return {
    valid: errors.length === 0,
    errors,
    normalized: {
      tripId: String(tripId || '').trim(),
      driverUserId: user?.id ? String(user.id).trim() : null,
      thanh_pho,
    },
  };
}

function validateHistoryParams(userId, query) {
  const errors = [];
  const normalizedCity = normalizeCity(query?.thanh_pho);
  const limit = query?.limit ? Number(query.limit) : 20;
  const offset = query?.offset ? Number(query.offset) : 0;

  if (!userId || !String(userId).trim()) {
    errors.push('userId là bắt buộc');
  }

  if (query?.thanh_pho && !normalizedCity) {
    errors.push('thanh_pho chỉ được là HCM hoặc HN');
  }

  if (!Number.isInteger(limit) || limit <= 0 || limit > 100) {
    errors.push('limit phải là số nguyên từ 1 đến 100');
  }

  if (!Number.isInteger(offset) || offset < 0) {
    errors.push('offset phải là số nguyên >= 0');
  }

  return {
    valid: errors.length === 0,
    errors,
    normalized: {
      userId: String(userId || '').trim(),
      thanh_pho: normalizedCity,
      limit,
      offset,
    },
  };
}

module.exports = {
  validateCreateTripPayload,
  validateHistoryParams,
  validatePendingTripsParams,
  validateTripActionPayload,
  normalizeCity,
};
