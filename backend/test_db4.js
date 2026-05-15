const sql = require('mssql');
async function test() {
  const pool = await sql.connect({
    server: 'localhost',
    port: 60011,
    database: 'RideApp_Nam_Replica',
    user: 'rideapp',
    password: '123456',
    options: { trustServerCertificate: true }
  });
  const r = await pool.query("SELECT id, email, ho_ten, thanh_pho FROM users WHERE email = 'taixe6_hn@gmail.com'");
  console.log(r.recordset);
  pool.close();
}
test();
