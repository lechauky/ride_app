const sql = require('mssql');

const dbBase = {
  server: 'localhost',
  user: 'rideapp',
  password: '123456',
  options: { encrypt: false, trustServerCertificate: true },
  pool: { max: 10, min: 0, idleTimeoutMillis: 30000 },
};

const databases = [
  {
    name: 'NAM_PRIMARY',
    city: 'HCM',
    port: 50011,
    database: 'RideApp_Nam',
    label: 'TP.HCM',
  },
  {
    name: 'BAC_PRIMARY',
    city: 'HN',
    port: 50021,
    database: 'RideApp_Bac',
    label: 'Hà Nội',
  },
];

const familyNames = [
  'Nguyễn',
  'Trần',
  'Lê',
  'Phạm',
  'Huỳnh',
  'Hoàng',
  'Phan',
  'Vũ',
  'Võ',
  'Đặng',
  'Bùi',
  'Đỗ',
  'Hồ',
  'Ngô',
  'Dương',
  'Lý',
];

const middleNames = [
  'Văn',
  'Thị',
  'Minh',
  'Thanh',
  'Ngọc',
  'Quốc',
  'Gia',
  'Hữu',
  'Phương',
  'Anh',
];

const givenNames = [
  'An',
  'Bảo',
  'Cường',
  'Dung',
  'Giang',
  'Hải',
  'Khoa',
  'Linh',
  'Long',
  'Mai',
  'Nam',
  'Oanh',
  'Phúc',
  'Quân',
  'Tâm',
  'Tuấn',
  'Vinh',
  'Yến',
];

const carBrands = ['Honda', 'Yamaha', 'Toyota', 'Hyundai', 'Kia', 'Ford', 'Mazda', 'VinFast'];
const colors = ['Đỏ', 'Đen', 'Trắng', 'Bạc', 'Xanh dương', 'Xám'];

function pick(list, index) {
  return list[index % list.length];
}

function demoName(index) {
  return `${pick(familyNames, index)} ${pick(middleNames, index * 3)} ${pick(givenNames, index * 5)}`;
}

async function countBadRows(pool) {
  const result = await pool.request().query(`
    SELECT
      (SELECT COUNT(*) FROM users WHERE ho_ten LIKE '%?%') AS bad_users,
      (SELECT COUNT(*) FROM drivers WHERE ho_ten LIKE '%?%') AS bad_drivers,
      (SELECT COUNT(*) FROM trips WHERE dia_chi_diem_don LIKE '%?%' OR dia_chi_diem_den LIKE '%?%') AS bad_trips,
      (SELECT COUNT(*) FROM vehicles WHERE hang_xe LIKE '%?%' OR mau_xe LIKE '%?%') AS bad_vehicles
  `);
  return result.recordset[0];
}

async function repairUsers(pool) {
  const result = await pool.request().query(`
    SELECT id
    FROM users
    WHERE ho_ten LIKE '%?%'
    ORDER BY ngay_tao, email
  `);

  for (let i = 0; i < result.recordset.length; i += 1) {
    await pool.request()
      .input('id', sql.UniqueIdentifier, result.recordset[i].id)
      .input('ho_ten', sql.NVarChar(100), demoName(i))
      .query('UPDATE users SET ho_ten = @ho_ten WHERE id = @id');
  }
}

async function repairDrivers(pool) {
  await pool.request().query(`
    UPDATE d
    SET d.ho_ten = u.ho_ten
    FROM drivers d
    JOIN users u ON u.id = d.ma_user
    WHERE d.ho_ten LIKE '%?%'
  `);
}

async function repairVehicles(pool) {
  const result = await pool.request().query(`
    SELECT id
    FROM vehicles
    WHERE hang_xe LIKE '%?%' OR mau_xe LIKE '%?%'
    ORDER BY bien_so
  `);

  for (let i = 0; i < result.recordset.length; i += 1) {
    await pool.request()
      .input('id', sql.UniqueIdentifier, result.recordset[i].id)
      .input('hang_xe', sql.NVarChar(50), pick(carBrands, i))
      .input('mau_xe', sql.NVarChar(30), pick(colors, i * 2))
      .query('UPDATE vehicles SET hang_xe = @hang_xe, mau_xe = @mau_xe WHERE id = @id');
  }
}

async function repairTrips(pool, label) {
  const result = await pool.request().query(`
    SELECT id
    FROM trips
    WHERE dia_chi_diem_don LIKE '%?%' OR dia_chi_diem_den LIKE '%?%'
    ORDER BY ngay_tao, id
  `);

  for (let i = 0; i < result.recordset.length; i += 1) {
    const order = String(i + 1).padStart(3, '0');
    await pool.request()
      .input('id', sql.UniqueIdentifier, result.recordset[i].id)
      .input('dia_chi_diem_don', sql.NVarChar(255), `Điểm đón demo ${label} ${order}`)
      .input('dia_chi_diem_den', sql.NVarChar(255), `Điểm đến demo ${label} ${order}`)
      .query(`
        UPDATE trips
        SET dia_chi_diem_don = @dia_chi_diem_don,
            dia_chi_diem_den = @dia_chi_diem_den
        WHERE id = @id
      `);
  }
}

async function repairDatabase(config) {
  const pool = await new sql.ConnectionPool({
    ...dbBase,
    port: config.port,
    database: config.database,
  }).connect();

  try {
    const before = await countBadRows(pool);
    await repairUsers(pool);
    await repairDrivers(pool);
    await repairVehicles(pool);
    await repairTrips(pool, config.label);
    const after = await countBadRows(pool);
    console.log(`${config.name}: before=${JSON.stringify(before)} after=${JSON.stringify(after)}`);
  } finally {
    await pool.close();
  }
}

(async () => {
  for (const config of databases) {
    await repairDatabase(config);
  }
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
