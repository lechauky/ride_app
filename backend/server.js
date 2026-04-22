// ===========================================
// SERVER.JS - Entry Point của Backend
// Đồ án: Ứng dụng Gọi xe - CSDL Phân Tán
// ===========================================

const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware chung
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ================== ROUTES ==================
// Thành viên 1: Auth (Đăng ký / Đăng nhập)
const authRoutes = require('./routes/authRoutes');
app.use('/api/auth', authRoutes);

// Thành viên 2: Tài xế
const driverRoutes = require('./routes/driverRoutes');
app.use('/api/drivers', driverRoutes);

// Thành viên 3: Chuyến đi
const tripRoutes = require('./routes/tripRoutes');
app.use('/api/trips', tripRoutes);

// ================== HEALTH CHECK ==================
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        message: 'Server Backend đang hoạt động bình thường',
        data: {
            port: PORT,
            region: process.env.SERVER_REGION || 'DEFAULT',
            mode: process.env.SERVER_MODE || 'PRIMARY',
            timestamp: new Date().toISOString()
        }
    });
});

// ================== KHỞI ĐỘNG SERVER ==================
const PORT = process.env.PORT || 5001;

app.listen(PORT, () => {
    console.log(`🚀 Server Backend đang chạy tại: http://localhost:${PORT}`);
    console.log(`📍 Khu vực: ${process.env.SERVER_REGION || 'Chưa cấu hình'}`);
    console.log(`📡 Chế độ: ${process.env.SERVER_MODE || 'PRIMARY'}`);
});
