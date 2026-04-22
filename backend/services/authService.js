// ===========================================
// SERVICE - XÁC THỰC (Auth)
// Thành viên 1 phụ trách hoàn thiện file này
// TV1: Viết logic bcrypt hash password, tạo JWT token
// ===========================================

const { executeWithFailover } = require('../middlewares/failover');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// TODO (TV1): Hoàn thiện logic đăng ký
const register = async ({ ho_ten, email, mat_khau, so_dien_thoai, thanh_pho }) => {
    // Mã hóa mật khẩu
    const hashedPassword = await bcrypt.hash(mat_khau, 10);

    // Gọi Fail-over query (TV5 đã viết sẵn hàm này)
    const query = `INSERT INTO users (ho_ten, email, mat_khau, so_dien_thoai, thanh_pho)
                 VALUES (@ho_ten, @email, @mat_khau, @so_dien_thoai, @thanh_pho)`;

    await executeWithFailover(thanh_pho, query, {
        ho_ten, email, mat_khau: hashedPassword, so_dien_thoai, thanh_pho
    });

    return { success: true, message: 'Đăng ký thành công!', data: null };
};

// TODO (TV1): Hoàn thiện logic đăng nhập
const login = async ({ email, mat_khau, thanh_pho }) => {
    const query = `SELECT * FROM users WHERE email = @email`;
    const { result } = await executeWithFailover(thanh_pho, query, { email });

    if (!result || result.length === 0) {
        return { success: false, message: 'Email không tồn tại.', data: null };
    }

    const user = result[0];
    const isMatch = await bcrypt.compare(mat_khau, user.mat_khau);

    if (!isMatch) {
        return { success: false, message: 'Mật khẩu không đúng.', data: null };
    }

    // Tạo token JWT
    const token = jwt.sign(
        { id: user.id, email: user.email, thanh_pho: user.thanh_pho },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    return {
        success: true,
        message: 'Đăng nhập thành công!',
        data: { token, user: { id: user.id, ho_ten: user.ho_ten, email: user.email } }
    };
};

// TODO (TV1): Hoàn thiện logic lấy profile
const getProfile = async (userId, thanhPho) => {
    const query = `SELECT id, ho_ten, email, so_dien_thoai, thanh_pho, ngay_tao FROM users WHERE id = @userId`;
    const { result } = await executeWithFailover(thanhPho, query, { userId });

    if (!result || result.length === 0) {
        return { success: false, message: 'Không tìm thấy người dùng.', data: null };
    }

    return { success: true, message: 'Lấy thông tin thành công.', data: result[0] };
};

module.exports = { register, login, getProfile };
