const sql = require('mssql');
async function test() {
  const pool = await sql.connect({
    server: 'localhost',
    port: 50011,
    database: 'RideApp_Nam',
    user: 'rideapp',
    password: '123456Aa',
    options: { trustServerCertificate: true }
  });
  const r = await pool.query("SELECT id, email, ho_ten, thanh_pho FROM users WHERE email = 'taixe6_hn@gmail.com'");
  console.log(r.recordset);
  pool.close();
}
test();
