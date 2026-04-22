// ===========================================
// ROUTES - XÁC THỰC (Auth)
// Thành viên 1 phụ trách file này
// ===========================================

const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// POST /api/auth/register - Đăng ký tài khoản mới
router.post('/register', authController.register);

// POST /api/auth/login - Đăng nhập
router.post('/login', authController.login);

// GET /api/auth/profile - Xem thông tin cá nhân (cần token)
const authMiddleware = require('../middlewares/auth');
router.get('/profile', authMiddleware, authController.getProfile);

module.exports = router;
