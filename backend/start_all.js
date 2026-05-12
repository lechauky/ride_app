require('dotenv').config();
const createApp = require('./user-auth/app');

const ports = [5001, 5002, 6001, 6002];

ports.forEach(port => {
  const app = createApp(port);
  app.listen(port, () => {
    let name = '';
    if (port === 5001) name = '[Miền Nam - Primary]';
    if (port === 5002) name = '[Miền Bắc - Primary]';
    if (port === 6001) name = '[Miền Nam - Backup] ';
    if (port === 6002) name = '[Miền Bắc - Backup] ';

    console.log(`✅ ${name} API đang chạy tại port ${port}`);
  });
});

console.log('🚀 Đang khởi động toàn bộ cụm Server phân tán...');
