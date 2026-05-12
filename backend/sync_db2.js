require('dotenv').config();
const sql = require('mssql');

const dbConfigs = {
  NAM_PRIMARY: { server: 'localhost', port: 50011, database: 'RideApp_Nam', user: 'rideapp', password: '123456', options: { trustServerCertificate: true } },
  NAM_REPLICA: { server: 'localhost', port: 60011, database: 'RideApp_Nam_Replica', user: 'rideapp', password: '123456', options: { trustServerCertificate: true } },
  BAC_PRIMARY: { server: 'localhost', port: 50021, database: 'RideApp_Bac', user: 'rideapp', password: '123456', options: { trustServerCertificate: true } },
  BAC_REPLICA: { server: 'localhost', port: 60021, database: 'RideApp_Bac_Replica', user: 'rideapp', password: '123456', options: { trustServerCertificate: true } },
};

const tables = [
  'driver_location_logs', 'notifications', 'ratings', 'payments',
  'trip_assignments', 'trips', 'vehicles', 'drivers', 'users', 'ride_types'
];

async function syncData(primaryConf, replicaConf) {
  console.log(`Đang đồng bộ từ ${primaryConf.database} sang ${replicaConf.database}...`);
  const poolPri = await sql.connect(primaryConf);
  const poolRep = await new sql.ConnectionPool(replicaConf).connect();

  await poolRep.query(`USE [master]; ALTER DATABASE [${replicaConf.database}] SET READ_WRITE; USE [${replicaConf.database}];`);

  for (const table of tables) {
    console.log(`  -> Đang xóa dữ liệu bảng ${table} trên Replica...`);
    await poolRep.query(`DELETE FROM dbo.${table}`);
  }

  const tablesToSync = [...tables].reverse(); // Insert order: users, drivers, etc.
  for (const table of tablesToSync) {
    console.log(`  -> Đang copy dữ liệu bảng ${table}...`);
    const r = await poolPri.query(`SELECT * FROM ${table}`);
    const rows = r.recordset;
    if (rows.length === 0) continue;

    const hasIdentity = table === 'driver_location_logs';
    if (hasIdentity) await poolRep.query(`SET IDENTITY_INSERT dbo.${table} ON`);

    for (let i = 0; i < rows.length; i += 50) {
      const chunk = rows.slice(i, i + 50);
      const cols = Object.keys(chunk[0]);
      let insertQuery = `INSERT INTO dbo.${table} (${cols.join(', ')}) VALUES `;
      let valuesArr = [];
      chunk.forEach(row => {
        const vals = cols.map(c => {
          let v = row[c];
          if (v === null || v === undefined) return 'NULL';
          if (typeof v === 'string') return `N'${v.replace(/'/g, "''")}'`;
          if (v instanceof Date) return `'${v.toISOString()}'`;
          if (typeof v === 'boolean') return v ? '1' : '0';
          return v;
        });
        valuesArr.push(`(${vals.join(', ')})`);
      });
      insertQuery += valuesArr.join(', ');
      await poolRep.query(insertQuery);
    }

    if (hasIdentity) await poolRep.query(`SET IDENTITY_INSERT dbo.${table} OFF`);
  }

  await poolRep.query(`USE [master]; ALTER DATABASE [${replicaConf.database}] SET READ_ONLY;`);

  await poolPri.close();
  await poolRep.close();
  console.log(`Đồng bộ ${replicaConf.database} hoàn tất!`);
}

async function main() {
  try {
    await syncData(dbConfigs.NAM_PRIMARY, dbConfigs.NAM_REPLICA);
    await syncData(dbConfigs.BAC_PRIMARY, dbConfigs.BAC_REPLICA);
    console.log('Tất cả đồng bộ hoàn tất!');
  } catch (err) {
    console.error(err);
  }
}
main();
