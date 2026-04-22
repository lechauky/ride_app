// ===========================================
// MIDDLEWARE XÁC THỰC JWT
// Thành viên 1 phụ trách file này
// ===========================================

const jwt = require('jsonwebtoken');
require('dotenv').config();

/**
 * Middleware kiểm tra token JWT từ header Authorization
 * Cách dùng: router.get('/profile', authMiddleware, controller.getProfile);
 */
function authMiddleware(req, res, next) {
    try {
        const authHeader = req.headers['authorization'];

        if (!authHeader) {
            return res.status(403).json({
                success: false,
                message: 'Không tìm thấy token xác thực. Vui lòng đăng nhập.',
                data: null
            });
        }

        // Token format: "Bearer <token>"
        const token = authHeader.split(' ')[1];

        if (!token) {
            return res.status(403).json({
                success: false,
                message: 'Token không hợp lệ.',
                data: null
            });
        }

        // Giải mã token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded; // Gắn thông tin user vào request
        next();

    } catch (error) {
        console.log('❌ Lỗi xác thực token:', error.message);
        return res.status(403).json({
            success: false,
            message: 'Token hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.',
            data: null
        });
    }
}

module.exports = authMiddleware;
