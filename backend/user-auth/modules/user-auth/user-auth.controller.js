const service = require('./user-auth.service');

async function register(req, res) {
  try {
    const result = await service.register(req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Lỗi đăng ký', error: error.message });
  }
}

async function login(req, res) {
  try {
    const result = await service.login(req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Lỗi đăng nhập', error: error.message });
  }
}

async function me(req, res) {
  try {
    const result = await service.me(req.user.id);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Lỗi lấy thông tin người dùng', error: error.message });
  }
}

module.exports = { register, login, me };
