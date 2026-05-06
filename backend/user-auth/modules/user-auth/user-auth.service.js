// ===========================================
// SERVICE - Thành viên 1 (Khánh)
// Nhiệm vụ: Xử lý logic nghiệp vụ Đăng ký / Đăng nhập
// Truyền thanh_pho xuống Repository để Định tuyến DB
// ===========================================
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const repository = require('./user-auth.repository');
const { validateRegisterPayload, validateLoginPayload } = require('./user-auth.validator');

async function findUserByEmailWithFallback(email, city) {
  try {
    const replicaUser = await repository.findUserByEmail(email, city);
    if (replicaUser) return replicaUser;
  } catch (_) {
    // Local demo may run without real replication; fall back to Primary.
  }

  return await repository.findUserByEmailPrimary(email, city);
}

async function getUserByIdWithFallback(userId, city) {
  try {
    const replicaUser = await repository.getUserById(userId, city);
    if (replicaUser) return replicaUser;
  } catch (_) {
    // Local demo may run without real replication; fall back to Primary.
  }

  return await repository.getUserByIdPrimary(userId, city);
}

async function register(payload) {
  const validation = validateRegisterPayload(payload);
  if (!validation.valid) {
    return { status: 400, body: { success: false, message: validation.errors.join(', ') } };
  }

  const { ho_ten, email, mat_khau, so_dien_thoai } = payload;
  const city = validation.normalized.thanh_pho || 'HCM';
  const role = validation.normalized.vai_tro || 'user';

  // Kiểm tra email đã tồn tại chưa (SELECT → Replica)
  const normalizedEmail = String(email).trim().toLowerCase();
  const existing = await findUserByEmailWithFallback(normalizedEmail, city)
    || await findUserByEmailWithFallback(normalizedEmail, city === 'HCM' ? 'HN' : 'HCM');
  if (existing) {
    return { status: 409, body: { success: false, message: 'Email đã tồn tại' } };
  }

  // Tạo user mới (INSERT → Primary)
  const hashedPassword = await bcrypt.hash(mat_khau, 10);
  const user = await repository.createUser({
    ho_ten: String(ho_ten).trim(),
    email: normalizedEmail,
    mat_khau: hashedPassword,
    so_dien_thoai: so_dien_thoai ? String(so_dien_thoai).trim() : null,
    thanh_pho: city,
    vai_tro: role,
  });

  const token = jwt.sign(
    { id: user.id, email: user.email, ho_ten: user.ho_ten, thanh_pho: user.thanh_pho, vai_tro: user.vai_tro },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

  return {
    status: 201,
    body: {
      success: true,
      message: 'Đăng ký thành công',
      token,
      data: user,
    },
  };
}

async function login(payload) {
  const validation = validateLoginPayload(payload);
  if (!validation.valid) {
    return { status: 400, body: { success: false, message: validation.errors.join(', ') } };
  }

  const { email, mat_khau, thanh_pho } = payload;

  // Tự động tìm user trên cả 2 DB nếu không truyền thanh_pho
  const normalizedEmail = String(email).trim().toLowerCase();
  let user = await findUserByEmailWithFallback(normalizedEmail, thanh_pho || 'HCM');
  
  if (!user && !thanh_pho) {
    user = await findUserByEmailWithFallback(normalizedEmail, 'HN');
  }

  if (!user) {
    return { status: 401, body: { success: false, message: 'Email hoặc mật khẩu không đúng' } };
  }

  const ok = await bcrypt.compare(mat_khau, user.mat_khau);
  if (!ok) {
    return { status: 401, body: { success: false, message: 'Email hoặc mật khẩu không đúng' } };
  }

  const token = jwt.sign(
    { id: user.id, email: user.email, ho_ten: user.ho_ten, thanh_pho: user.thanh_pho, vai_tro: user.vai_tro },
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
        vai_tro: user.vai_tro,
        ngay_tao: user.ngay_tao,
      },
    },
  };
}

async function me(userId, thanh_pho = 'HCM') {
  // Lấy thông tin user (SELECT → Replica)
  const user = await getUserByIdWithFallback(userId, thanh_pho);
  if (!user) {
    return { status: 404, body: { success: false, message: 'Không tìm thấy người dùng' } };
  }

  return { status: 200, body: { success: true, data: user } };
}

module.exports = { register, login, me };
