// ===========================================
// CONTROLLER - XÁC THỰC (Auth)
// Thành viên 1 phụ trách file này
// ===========================================

const authService = require('../services/authService');

// POST /api/auth/register
const register = async (req, res) => {
    try {
        const { ho_ten, email, mat_khau, so_dien_thoai, thanh_pho } = req.body;

        // Validate input
        if (!ho_ten || !email || !mat_khau || !so_dien_thoai || !thanh_pho) {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng điền đầy đủ thông tin đăng ký.',
                data: null
            });
        }

        const result = await authService.register({ ho_ten, email, mat_khau, so_dien_thoai, thanh_pho });
        return res.status(201).json(result);

    } catch (error) {
        console.log('❌ Lỗi đăng ký:', error.message);

        // Xử lý lỗi Read-Only (Fail-over sang Replica)
        if (error.isReadOnly) {
            return res.status(503).json({
                success: false,
                message: error.message,
                data: null
            });
        }

        return res.status(500).json({
            success: false,
            message: 'Lỗi hệ thống khi đăng ký.',
            data: null
        });
    }
};

// POST /api/auth/login
const login = async (req, res) => {
    try {
        const { email, mat_khau, thanh_pho } = req.body;

        if (!email || !mat_khau || !thanh_pho) {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng nhập email, mật khẩu và chọn thành phố.',
                data: null
            });
        }

        const result = await authService.login({ email, mat_khau, thanh_pho });
        return res.status(200).json(result);

    } catch (error) {
        console.log('❌ Lỗi đăng nhập:', error.message);
        return res.status(500).json({
            success: false,
            message: 'Lỗi hệ thống khi đăng nhập.',
            data: null
        });
    }
};

// GET /api/auth/profile
const getProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const thanhPho = req.user.thanh_pho;

        const result = await authService.getProfile(userId, thanhPho);
        return res.status(200).json(result);

    } catch (error) {
        console.log('❌ Lỗi lấy profile:', error.message);
        return res.status(500).json({
            success: false,
            message: 'Lỗi hệ thống khi lấy thông tin cá nhân.',
            data: null
        });
    }
};

module.exports = { register, login, getProfile };
