function normalizeCity(city) {
  if (!city) return null;
  const value = String(city).trim().toUpperCase();
  return value === 'HCM' || value === 'HN' ? value : null;
}

function validateListParams(user, query) {
  const errors = [];
  const thanh_pho = normalizeCity(query?.thanh_pho || user?.thanh_pho);
  const limit = query?.limit ? Number(query.limit) : 20;
  const offset = query?.offset ? Number(query.offset) : 0;

  if (!user?.id) errors.push('Thiếu người nhận thông báo');
  if (!thanh_pho) errors.push('thanh_pho chỉ được là HCM hoặc HN');
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
      userId: user?.id || null,
      thanh_pho,
      limit,
      offset,
    },
  };
}

function validateNotificationAction(notificationId, user, body) {
  const errors = [];
  const thanh_pho = normalizeCity(body?.thanh_pho || user?.thanh_pho);

  if (!notificationId || !String(notificationId).trim()) {
    errors.push('notificationId là bắt buộc');
  }
  if (!user?.id) errors.push('Thiếu người nhận thông báo');
  if (!thanh_pho) errors.push('thanh_pho chỉ được là HCM hoặc HN');

  return {
    valid: errors.length === 0,
    errors,
    normalized: {
      notificationId: String(notificationId || '').trim(),
      userId: user?.id || null,
      thanh_pho,
    },
  };
}

function validateMarkAllPayload(user, body) {
  const errors = [];
  const thanh_pho = normalizeCity(body?.thanh_pho || user?.thanh_pho);

  if (!user?.id) errors.push('Thiếu người nhận thông báo');
  if (!thanh_pho) errors.push('thanh_pho chỉ được là HCM hoặc HN');

  return {
    valid: errors.length === 0,
    errors,
    normalized: {
      userId: user?.id || null,
      thanh_pho,
    },
  };
}

module.exports = {
  validateListParams,
  validateNotificationAction,
  validateMarkAllPayload,
};
