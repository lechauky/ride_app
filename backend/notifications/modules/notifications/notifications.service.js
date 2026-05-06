const repository = require('./notifications.repository');
const {
  validateListParams,
  validateNotificationAction,
  validateMarkAllPayload,
} = require('./notifications.validator');

async function getNotifications(user, query) {
  const validation = validateListParams(user, query);
  if (!validation.valid) {
    return {
      status: 400,
      body: { success: false, message: validation.errors.join(', ') },
    };
  }

  const notifications = await repository.getNotifications(validation.normalized);

  return {
    status: 200,
    body: {
      success: true,
      message: `Lấy thông báo thành công (${notifications.length})`,
      data: notifications,
    },
  };
}

async function markRead(notificationId, user, body) {
  const validation = validateNotificationAction(notificationId, user, body);
  if (!validation.valid) {
    return {
      status: 400,
      body: { success: false, message: validation.errors.join(', ') },
    };
  }

  const notification = await repository.markRead(validation.normalized);
  if (!notification) {
    return {
      status: 404,
      body: { success: false, message: 'Không tìm thấy thông báo' },
    };
  }

  return {
    status: 200,
    body: {
      success: true,
      message: 'Đã đánh dấu thông báo là đã đọc',
      data: notification,
    },
  };
}

async function markAllRead(user, body) {
  const validation = validateMarkAllPayload(user, body);
  if (!validation.valid) {
    return {
      status: 400,
      body: { success: false, message: validation.errors.join(', ') },
    };
  }

  const updated = await repository.markAllRead(validation.normalized);

  return {
    status: 200,
    body: {
      success: true,
      message: `Đã đánh dấu ${updated} thông báo là đã đọc`,
      data: { updated },
    },
  };
}

async function softDelete(notificationId, user, body) {
  const validation = validateNotificationAction(notificationId, user, body);
  if (!validation.valid) {
    return {
      status: 400,
      body: { success: false, message: validation.errors.join(', ') },
    };
  }

  const updated = await repository.softDelete(validation.normalized);
  if (!updated) {
    return {
      status: 404,
      body: { success: false, message: 'Không tìm thấy thông báo' },
    };
  }

  return {
    status: 200,
    body: {
      success: true,
      message: 'Đã xoá thông báo',
      data: { deleted: true },
    },
  };
}

module.exports = {
  getNotifications,
  markRead,
  markAllRead,
  softDelete,
};
