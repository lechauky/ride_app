const test = require('node:test');
const assert = require('node:assert/strict');
const {
  validateCreateTripPayload,
  validatePendingTripsParams,
  validateTripDetailsParams,
} = require('../trips/modules/trips/trips.validator');

function validCreatePayload(overrides = {}) {
  return {
    ma_nguoi_dung: '9D4CC8F9-7A5C-4A53-8F18-6DF42A60B111',
    ma_loai_dich_vu: 'bike',
    thanh_pho: 'HCM',
    vi_do_diem_don: 10.7769,
    kinh_do_diem_don: 106.7009,
    vi_do_diem_den: 10.78,
    kinh_do_diem_den: 106.71,
    khoang_cach_km: 2,
    ...overrides,
  };
}

test('validateCreateTripPayload chấp nhận HCM và HN', () => {
  assert.equal(validateCreateTripPayload(validCreatePayload({ thanh_pho: 'HCM' })).valid, true);
  assert.equal(validateCreateTripPayload(validCreatePayload({ thanh_pho: 'HN' })).valid, true);
});

test('validateCreateTripPayload từ chối thành phố không hỗ trợ', () => {
  const result = validateCreateTripPayload(validCreatePayload({ thanh_pho: 'DN' }));

  assert.equal(result.valid, false);
  assert.match(result.errors.join(', '), /thanh_pho/);
});

test('validateCreateTripPayload từ chối tọa độ ngoài phạm vi', () => {
  const result = validateCreateTripPayload(validCreatePayload({
    vi_do_diem_don: 91,
    kinh_do_diem_den: 181,
  }));

  assert.equal(result.valid, false);
  assert.match(result.errors.join(', '), /vi_do_diem_don/);
  assert.match(result.errors.join(', '), /kinh_do_diem_den/);
});

test('validatePendingTripsParams kiểm tra thành phố và tọa độ tài xế', () => {
  const ok = validatePendingTripsParams({
    thanh_pho: 'HN',
    latitude: 21.0285,
    longitude: 105.8542,
  });
  const invalid = validatePendingTripsParams({
    thanh_pho: 'DN',
    latitude: -91,
    longitude: 105.8542,
  });

  assert.equal(ok.valid, true);
  assert.equal(invalid.valid, false);
  assert.match(invalid.errors.join(', '), /thanh_pho/);
  assert.match(invalid.errors.join(', '), /latitude/);
});

test('validateTripDetailsParams yêu cầu tripId và thành phố hợp lệ', () => {
  const ok = validateTripDetailsParams('9D4CC8F9-7A5C-4A53-8F18-6DF42A60B111', {
    thanh_pho: 'HN',
  });
  const invalid = validateTripDetailsParams('', { thanh_pho: 'DN' });

  assert.equal(ok.valid, true);
  assert.equal(ok.normalized.thanh_pho, 'HN');
  assert.equal(invalid.valid, false);
  assert.match(invalid.errors.join(', '), /tripId/);
  assert.match(invalid.errors.join(', '), /thanh_pho/);
});
