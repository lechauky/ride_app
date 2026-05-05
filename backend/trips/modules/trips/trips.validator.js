function normalizeCity(city) {
  if (!city) return null;
  const value = String(city).trim().toUpperCase();
  return value === 'HCM' || value === 'HN' ? value : null;
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

  if (!body.ma_loai_dich_vu || !String(body.ma_loai_dich_vu).trim()) {
    errors.push('ma_loai_dich_vu là bắt buộc');
  }

  const thanh_pho = normalizeCity(body.thanh_pho);
  if (!thanh_pho) {
    errors.push('thanh_pho chỉ được là HCM hoặc HN');
  }

  if (!isValidLatitude(body.vi_do_diem_don)) errors.push('vi_do_diem_don không hợp lệ');
  if (!isValidLongitude(body.kinh_do_diem_don)) errors.push('kinh_do_diem_don không hợp lệ');
  if (!isValidLatitude(body.vi_do_diem_den)) errors.push('vi_do_diem_den không hợp lệ');
  if (!isValidLongitude(body.kinh_do_diem_den)) errors.push('kinh_do_diem_den không hợp lệ');

  return {
    valid: errors.length === 0,
    errors,
    normalized: {
      ma_nguoi_dung: body.ma_nguoi_dung ? String(body.ma_nguoi_dung).trim() : null,
      ma_loai_dich_vu: body.ma_loai_dich_vu ? String(body.ma_loai_dich_vu).trim() : null,
      vi_do_diem_don: Number(body.vi_do_diem_don),
      kinh_do_diem_don: Number(body.kinh_do_diem_don),
      vi_do_diem_den: Number(body.vi_do_diem_den),
      kinh_do_diem_den: Number(body.kinh_do_diem_den),
      dia_chi_diem_don: body.dia_chi_diem_don ? String(body.dia_chi_diem_don).trim() : null,
      dia_chi_diem_den: body.dia_chi_diem_den ? String(body.dia_chi_diem_den).trim() : null,
      khoang_cach_km: body.khoang_cach_km === undefined || body.khoang_cach_km === null
        ? null
        : Number(body.khoang_cach_km),
      thanh_pho,
      trang_thai: body.trang_thai ? String(body.trang_thai).trim() : 'cho_xu_ly',
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
  normalizeCity,
};
