const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const createApp = require('../user-auth/app');

function request(app, options = {}) {
  return new Promise((resolve, reject) => {
    const server = app.listen(0, '127.0.0.1', () => {
      const address = server.address();
      const req = http.request({
        hostname: '127.0.0.1',
        port: address.port,
        method: options.method || 'GET',
        path: options.path || '/api/health',
        headers: options.headers || {},
      }, (res) => {
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
          body += chunk;
        });
        res.on('end', () => {
          server.close(() => {
            resolve({
              statusCode: res.statusCode,
              body: body ? JSON.parse(body) : null,
            });
          });
        });
      });
      req.on('error', (error) => {
        server.close(() => reject(error));
      });
      if (options.body) req.write(options.body);
      req.end();
    });
  });
}

test('backup port cho phép GET health', async () => {
  const res = await request(createApp(6001));

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
});

test('backup port chặn thao tác ghi bằng HTTP 503 read-only', async () => {
  const res = await request(createApp(6001), {
    method: 'POST',
    path: '/api/trips',
    headers: { 'Content-Type': 'application/json' },
    body: '{}',
  });

  assert.equal(res.statusCode, 503);
  assert.equal(res.body.success, false);
  assert.equal(res.body.read_only, true);
  assert.match(res.body.message, /chỉ xem/);
});
