const service = require('./notifications.service');

async function getNotifications(req, res) {
  try {
    const result = await service.getNotifications(req.user, req.query);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi lấy thông báo',
      error: error.message,
    });
  }
}

async function markRead(req, res) {
  try {
    const result = await service.markRead(req.params.notificationId, req.user, req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi cập nhật thông báo',
      error: error.message,
    });
  }
}

async function markAllRead(req, res) {
  try {
    const result = await service.markAllRead(req.user, req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi cập nhật thông báo',
      error: error.message,
    });
  }
}

async function softDelete(req, res) {
  try {
    const result = await service.softDelete(req.params.notificationId, req.user, req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi xoá thông báo',
      error: error.message,
    });
  }
}

module.exports = {
  getNotifications,
  markRead,
  markAllRead,
  softDelete,
};
