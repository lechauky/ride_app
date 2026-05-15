const sql = require('mssql');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

const servers = [
    { name: 'NAM_PRIMARY', port: 50011, dbName: 'RideApp_Nam', city: 'HCM', isReplica: false },
    { name: 'BAC_PRIMARY', port: 50021, dbName: 'RideApp_Bac', city: 'HN', isReplica: false },
    { name: 'NAM_REPLICA', port: 60011, dbName: 'RideApp_Nam_Replica', city: 'HCM', isReplica: true },
    { name: 'BAC_REPLICA', port: 60021, dbName: 'RideApp_Bac_Replica', city: 'HN', isReplica: true }
];

const replicaPairs = [
    {
        primary: servers.find(s => s.name === 'NAM_PRIMARY'),
        replica: servers.find(s => s.name === 'NAM_REPLICA')
    },
    {
        primary: servers.find(s => s.name === 'BAC_PRIMARY'),
        replica: servers.find(s => s.name === 'BAC_REPLICA')
    }
];

const copyTables = [
    'ride_types',
    'users',
    'drivers',
    'vehicles',
    'trips',
    'trip_assignments',
    'payments',
    'ratings',
    'notifications',
    'driver_location_logs'
];

const saConfig = {
    user: 'sa',
    password: '123456Aa',
    server: 'localhost',
    options: { encrypt: false, trustServerCertificate: true },
    pool: { max: 10, min: 0, idleTimeoutMillis: 30000 }
};

// Utilities
function randomInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function randomItem(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
function randomPhone() { return '0' + randomInt(900000000, 999999999); }
function randomLat(city) { return city === 'HCM' ? 10.762622 + (Math.random() * 0.1 - 0.05) : 21.028511 + (Math.random() * 0.1 - 0.05); }
function randomLon(city) { return city === 'HCM' ? 106.660172 + (Math.random() * 0.1 - 0.05) : 105.804817 + (Math.random() * 0.1 - 0.05); }

const ho = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Huỳnh', 'Hoàng', 'Phan', 'Vũ', 'Võ', 'Đặng', 'Bùi', 'Đỗ', 'Hồ', 'Ngô', 'Dương', 'Lý'];
const ten_dem = ['Văn', 'Thị', 'Hữu', 'Minh', 'Thanh', 'Ngọc', 'Quốc', 'Gia', 'Thảo', 'Phương'];
const ten = ['Anh', 'Bảo', 'Cường', 'Dũng', 'Em', 'Phong', 'Giang', 'Hải', 'Linh', 'Khoa', 'Long', 'Mai', 'Nam', 'Oanh', 'Phúc', 'Quân', 'Tâm', 'Tuấn', 'Vinh', 'Yến'];
const hang_xe = ['Honda', 'Yamaha', 'Toyota', 'Hyundai', 'Kia', 'Ford', 'Mazda'];
const mau_xe = ['Đỏ', 'Đen', 'Trắng', 'Bạc', 'Xanh dương', 'Xám'];

function generateName() {
    return `${randomItem(ho)} ${randomItem(ten_dem)} ${randomItem(ten)}`;
}

async function executeSqlFile(pool, filePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    const batches = content.split(/\r?\n\s*GO\s*\r?\n/i);
    for (let batch of batches) {
        if (batch.trim()) {
            await pool.request().query(batch);
        }
    }
}

function sqlName(name) {
    return `[${name.replace(/]/g, ']]')}]`;
}

function sqlValue(value) {
    if (value === null || value === undefined) return 'NULL';
    if (value instanceof Date) return `'${value.toISOString().replace(/'/g, "''")}'`;
    if (typeof value === 'boolean') return value ? '1' : '0';
    if (typeof value === 'number') return Number.isFinite(value) ? String(value) : 'NULL';
    return `N'${String(value).replace(/'/g, "''")}'`;
}

async function copyTable(sourcePool, targetPool, table) {
    const result = await sourcePool.request().query(`SELECT * FROM dbo.${sqlName(table)}`);
    const rows = result.recordset;
    if (rows.length === 0) return;

    const columns = Object.keys(rows[0]);
    const columnSql = columns.map(sqlName).join(', ');
    const isIdentityTable = table === 'driver_location_logs';

    if (isIdentityTable) {
        await targetPool.request().query(`SET IDENTITY_INSERT dbo.${sqlName(table)} ON;`);
    }

    try {
        for (let i = 0; i < rows.length; i += 50) {
            const chunk = rows.slice(i, i + 50);
            const valuesSql = chunk
                .map(row => `(${columns.map(col => sqlValue(row[col])).join(', ')})`)
                .join(', ');
            await targetPool.request().query(
                `INSERT INTO dbo.${sqlName(table)} (${columnSql}) VALUES ${valuesSql};`
            );
        }
    } finally {
        if (isIdentityTable) {
            await targetPool.request().query(`SET IDENTITY_INSERT dbo.${sqlName(table)} OFF;`);
        }
    }
}

async function copyPrimaryToReplica(primary, replica) {
    console.log(`\n🔁 Đồng bộ ${primary.dbName} -> ${replica.dbName}...`);
    const sourcePool = await new sql.ConnectionPool({
        ...saConfig,
        port: primary.port,
        database: primary.dbName
    }).connect();
    const targetPool = await new sql.ConnectionPool({
        ...saConfig,
        port: replica.port,
        database: replica.dbName
    }).connect();

    try {
        await targetPool.request().query(`USE [master]; ALTER DATABASE [${replica.dbName}] SET READ_WRITE;`);
        await targetPool.request().query(`USE [${replica.dbName}];`);

        for (const table of [...copyTables].reverse()) {
            console.log(`   -> Xóa dữ liệu replica: ${table}`);
            await targetPool.request().query(`DELETE FROM dbo.${sqlName(table)};`);
        }

        for (const table of copyTables) {
            console.log(`   -> Copy bảng: ${table}`);
            await copyTable(sourcePool, targetPool, table);
        }

        await targetPool.request().query(`USE [master]; ALTER DATABASE [${replica.dbName}] SET READ_ONLY;`);
        console.log(` ✅ Replica ${replica.name} đã giống primary và chuyển sang read-only.`);
    } finally {
        await sourcePool.close();
        await targetPool.close();
    }
}

async function generateRealisticData(pool, server) {
    console.log(`   -> Tạo hash mật khẩu...`);
    const defaultPassword = await bcrypt.hash('123456', 10);
    
    const request = pool.request();
    
    // 1. Sinh 50 Khách hàng (Users)
    console.log(`   -> Sinh 50 Khách hàng...`);
    let userIds = [];
    for (let i = 1; i <= 50; i++) {
        const id = sql.UNIQUEIDENTIFIER; // Using newid() in SQL
        const email = `khachhang${i}_${server.city.toLowerCase()}@gmail.com`;
        const ho_ten = generateName();
        
        const result = await pool.request().query(`
            INSERT INTO users (ho_ten, email, mat_khau, so_dien_thoai, thanh_pho, vai_tro)
            OUTPUT inserted.id
            VALUES (N'${ho_ten}', '${email}', '${defaultPassword}', '${randomPhone()}', '${server.city}', 'user');
        `);
        userIds.push(result.recordset[0].id);
    }

    // 2. Sinh 20 Tài xế (Drivers + Vehicles)
    console.log(`   -> Sinh 20 Tài xế & Xe cộ...`);
    let driverIds = [];
    for (let i = 1; i <= 20; i++) {
        const email = `taixe${i}_${server.city.toLowerCase()}@gmail.com`;
        const ho_ten = generateName();
        
        // Create user for driver
        const userRes = await pool.request().query(`
            INSERT INTO users (ho_ten, email, mat_khau, so_dien_thoai, thanh_pho, vai_tro)
            OUTPUT inserted.id
            VALUES (N'${ho_ten}', '${email}', '${defaultPassword}', '${randomPhone()}', '${server.city}', 'driver');
        `);
        const userId = userRes.recordset[0].id;
        
        // Create driver profile
        const isAvailable = randomInt(0, 1);
        const driverRes = await pool.request().query(`
            INSERT INTO drivers (ma_user, ho_ten, so_dien_thoai, vi_do_hien_tai, kinh_do_hien_tai, thanh_pho, is_available, tong_so_chuyen)
            OUTPUT inserted.id
            VALUES ('${userId}', N'${ho_ten}', '${randomPhone()}', ${randomLat(server.city)}, ${randomLon(server.city)}, '${server.city}', ${isAvailable}, ${randomInt(0, 100)});
        `);
        const driverId = driverRes.recordset[0].id;
        driverIds.push({ id: driverId, type: randomItem(['bike', 'car4', 'car7']) });
        
        // Create vehicle
        const dType = driverIds[driverIds.length-1].type;
        const loai_xe = dType === 'bike' ? 'xe_may' : (dType === 'car4' ? 'o_to_4_cho' : 'o_to_7_cho');
        const bien_so = `${randomInt(10, 99)}${randomItem(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'])}1-${randomInt(10000, 99999)}`;
        
        await pool.request().query(`
            INSERT INTO vehicles (ma_tai_xe, loai_xe, bien_so, hang_xe, mau_xe, nam_san_xuat)
            VALUES ('${driverId}', '${loai_xe}', '${bien_so}', N'${randomItem(hang_xe)}', N'${randomItem(mau_xe)}', ${randomInt(2015, 2024)});
        `);
    }

    // 3. Sinh 100 Chuyến đi (Trips + Assignments + Payments)
    console.log(`   -> Sinh 100 Chuyến đi lịch sử...`);
    for (let i = 0; i < 100; i++) {
        const uId = randomItem(userIds);
        const dObj = randomItem(driverIds);
        const distance = (Math.random() * 15 + 1).toFixed(2);
        const trang_thai = randomItem(['hoan_thanh', 'hoan_thanh', 'hoan_thanh', 'da_huy', 'cho_xu_ly']);
        
        // Trip
        const tripRes = await pool.request().query(`
            INSERT INTO trips (ma_nguoi_dung, ma_loai_dich_vu, vi_do_diem_don, kinh_do_diem_don, dia_chi_diem_don, vi_do_diem_den, kinh_do_diem_den, dia_chi_diem_den, khoang_cach_km, trang_thai, thanh_pho)
            OUTPUT inserted.id
            VALUES ('${uId}', '${dObj.type}', ${randomLat(server.city)}, ${randomLon(server.city)}, N'Đại học Sài Gòn (${server.city})', ${randomLat(server.city)}, ${randomLon(server.city)}, N'Điểm đến ngẫu nhiên', ${distance}, '${trang_thai}', '${server.city}');
        `);
        const tripId = tripRes.recordset[0].id;
        
        // Assignment if assigned
        if (trang_thai !== 'cho_xu_ly') {
            const assignStatus = trang_thai === 'hoan_thanh' ? 'da_nhan' : 'tu_choi';
            await pool.request().query(`
                INSERT INTO trip_assignments (ma_chuyen_di, ma_tai_xe, trang_thai_nhan)
                VALUES ('${tripId}', '${dObj.id}', '${assignStatus}');
            `);
            
            // Payment if completed
            if (trang_thai === 'hoan_thanh') {
                const amount = Math.floor(distance * (dObj.type === 'bike' ? 4000 : 11000) + (dObj.type === 'bike' ? 12000 : 25000));
                await pool.request().query(`
                    INSERT INTO payments (ma_chuyen_di, so_tien, phuong_thuc, trang_thai)
                    VALUES ('${tripId}', ${amount}, '${randomItem(['tien_mat', 'vi_dien_tu'])}', 'da_thanh_toan');
                `);
                
                // Rating 80% chance
                if (Math.random() > 0.2) {
                    await pool.request().query(`
                        INSERT INTO ratings (ma_chuyen_di, nguoi_danh_gia, loai_nguoi_danh_gia, diem_so, nhan_xet)
                        VALUES ('${tripId}', '${uId}', 'user', ${randomInt(4, 5)}, N'Tài xế rất thân thiện!');
                    `);
                }
            }
        }
    }
}

async function seedServer(server) {
    console.log(`\n🚀 Bắt đầu: ${server.name} (Port: ${server.port})`);
    const config = { ...saConfig, port: server.port };
    let pool;
    try {
        pool = await new sql.ConnectionPool(config).connect();

        // 1. Xóa DB nếu đã tồn tại và tạo lại chỉ đúng DB của server này
        console.log(` - Khởi tạo Database [${server.dbName}]...`);
        await pool.request().query(`
            IF DB_ID(N'${server.dbName}') IS NOT NULL
            BEGIN
                ALTER DATABASE [${server.dbName}] SET READ_WRITE;
                ALTER DATABASE [${server.dbName}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                DROP DATABASE [${server.dbName}];
            END
            CREATE DATABASE [${server.dbName}];
        `);

        // 2. Tạo user rideapp dùng chung
        console.log(` - Cấp quyền User 'rideapp'...`);
        await pool.request().query(`
            IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'rideapp')
            BEGIN
                CREATE LOGIN [rideapp] WITH PASSWORD = '123456', CHECK_POLICY = OFF;
            END
            ALTER SERVER ROLE [sysadmin] ADD MEMBER [rideapp];
        `);

        // 3. Chạy Schema
        console.log(` - Import cấu trúc Schema (bảng, view)...`);
        await pool.request().query(`USE [${server.dbName}];`);
        await executeSqlFile(pool, path.join(__dirname, '02_schema_mssql.sql'));

        // 4. Sinh dữ liệu demo hoặc chờ copy từ primary
        if (server.isReplica) {
            console.log(` - Replica chỉ tạo schema, dữ liệu sẽ copy từ primary tương ứng...`);
        } else {
            console.log(` - Bắt đầu sinh dữ liệu ngẫu nhiên siêu thực...`);
            await generateRealisticData(pool, server);
        }

        console.log(` ✅ Hoàn tất ${server.name}!`);
    } catch (err) {
        console.error(` ❌ Lỗi tại ${server.name}:`, err.message);
        throw err;
    } finally {
        if (pool) await pool.close();
    }
}

async function main() {
    console.log("==================================================");
    console.log("  TRÌNH KHỞI TẠO DỮ LIỆU PHÂN TÁN (PRO VERSION)  ");
    console.log("==================================================");
    
    // Đợi xíu cho Docker SQL Server lên hẳn
    console.log("Đang đợi SQL Server khởi động...");
    await new Promise(r => setTimeout(r, 5000));

    for (const server of servers.filter(s => !s.isReplica)) {
        await seedServer(server);
    }

    for (const server of servers.filter(s => s.isReplica)) {
        await seedServer(server);
    }

    for (const pair of replicaPairs) {
        await copyPrimaryToReplica(pair.primary, pair.replica);
    }

    console.log("\n🎉 XONG! Primary đã được seed, replica đã được copy dữ liệu và đặt read-only.");
}

main().catch(err => {
    console.error("\n❌ Seed thất bại:", err.message);
    process.exitCode = 1;
});
