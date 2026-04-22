function normalizeCity(city) {
  if (!city) return null;
  const value = String(city).trim().toUpperCase();
  return value === 'HN' || value === 'HCM' ? value : null;
}

function validateRegisterPayload(payload) {
  const errors = [];
  const { ho_ten, email, mat_khau, thanh_pho } = payload || {};

  if (!ho_ten || !String(ho_ten).trim()) errors.push('ho_ten là bắt buộc');
  if (!email || !String(email).trim()) errors.push('email là bắt buộc');
  if (!mat_khau || !String(mat_khau).trim()) errors.push('mat_khau là bắt buộc');
  if (mat_khau && String(mat_khau).length < 6) errors.push('mat_khau phải có ít nhất 6 ký tự');

  const city = normalizeCity(thanh_pho);
  if (thanh_pho && !city) errors.push('thanh_pho chỉ được là HCM hoặc HN');

  return { valid: errors.length === 0, errors, normalized: { thanh_pho: city } };
}

function validateLoginPayload(payload) {
  const errors = [];
  const { email, mat_khau } = payload || {};

  if (!email || !String(email).trim()) errors.push('email là bắt buộc');
  if (!mat_khau || !String(mat_khau).trim()) errors.push('mat_khau là bắt buộc');

  return { valid: errors.length === 0, errors };
}

module.exports = { validateRegisterPayload, validateLoginPayload, normalizeCity };
