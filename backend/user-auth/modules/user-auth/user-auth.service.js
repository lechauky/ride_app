const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const repository = require('./user-auth.repository');
const { validateRegisterPayload, validateLoginPayload } = require('./user-auth.validator');

async function register(payload) {
  const validation = validateRegisterPayload(payload);
  if (!validation.valid) {
    return { status: 400, body: { success: false, message: validation.errors.join(', ') } };
  }

  const { ho_ten, email, mat_khau, so_dien_thoai, thanh_pho } = payload;

  const existing = await repository.findUserByEmail(email);
  if (existing) {
    return { status: 409, body: { success: false, message: 'Email đã tồn tại' } };
  }

  const hashedPassword = await bcrypt.hash(mat_khau, 10);
  const user = await repository.createUser({
    ho_ten: String(ho_ten).trim(),
    email: String(email).trim().toLowerCase(),
    mat_khau: hashedPassword,
    so_dien_thoai: so_dien_thoai ? String(so_dien_thoai).trim() : null,
    thanh_pho: validation.normalized.thanh_pho,
  });

  return {
    status: 201,
    body: {
      success: true,
      message: 'Đăng ký thành công',
      data: user,
    },
  };
}

async function login(payload) {
  const validation = validateLoginPayload(payload);
  if (!validation.valid) {
    return { status: 400, body: { success: false, message: validation.errors.join(', ') } };
  }

  const { email, mat_khau } = payload;
  const user = await repository.findUserByEmail(String(email).trim().toLowerCase());

  if (!user) {
    return { status: 401, body: { success: false, message: 'Email hoặc mật khẩu không đúng' } };
  }

  const ok = await bcrypt.compare(mat_khau, user.mat_khau);
  if (!ok) {
    return { status: 401, body: { success: false, message: 'Email hoặc mật khẩu không đúng' } };
  }

  const token = jwt.sign(
    { id: user.id, email: user.email, ho_ten: user.ho_ten },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

  return {
    status: 200,
    body: {
      success: true,
      message: 'Đăng nhập thành công',
      token,
      data: {
        id: user.id,
        ho_ten: user.ho_ten,
        email: user.email,
        so_dien_thoai: user.so_dien_thoai,
        thanh_pho: user.thanh_pho,
        ngay_tao: user.ngay_tao,
      },
    },
  };
}

async function me(userId) {
  const user = await repository.getUserById(userId);
  if (!user) {
    return { status: 404, body: { success: false, message: 'Không tìm thấy người dùng' } };
  }

  return { status: 200, body: { success: true, data: user } };
}

module.exports = { register, login, me };
