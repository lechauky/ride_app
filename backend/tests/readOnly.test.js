const test = require('node:test');
const assert = require('node:assert/strict');
const { assertWritableConnection, isWriteQuery } = require('../config/database');
const {
  READ_ONLY_HTTP_STATUS,
  isReadOnlyError,
  mapReadOnlyResult,
} = require('../utils/readOnly');

test('isWriteQuery phân biệt SELECT và các lệnh ghi', () => {
  assert.equal(isWriteQuery('SELECT * FROM trips'), false);
  assert.equal(isWriteQuery('  INSERT INTO trips DEFAULT VALUES'), true);
  assert.equal(isWriteQuery('\nUPDATE drivers SET is_available = 0'), true);
  assert.equal(isWriteQuery('DELETE FROM trips WHERE id = @id'), true);
  assert.equal(isWriteQuery('MERGE trips USING source ON 1 = 1'), true);
  assert.equal(isWriteQuery('EXEC dbo.sync_trips'), true);
});

test('read-only error được map thành HTTP 503', () => {
  const error = new Error('Hệ thống bảo trì, chỉ xem được lịch sử');
  error.code = 'READ_ONLY_MODE';

  const result = mapReadOnlyResult(error);

  assert.equal(isReadOnlyError(error), true);
  assert.equal(result.status, READ_ONLY_HTTP_STATUS);
  assert.equal(result.body.success, false);
  assert.equal(result.body.read_only, true);
  assert.match(result.body.message, /Server chính/);
});

test('lỗi kết nối primary được map thành HTTP 503 read-only', () => {
  const error = new Error('Failed to connect to mssql-nam-primary:1433 - getaddrinfo ENOTFOUND mssql-nam-primary');

  const result = mapReadOnlyResult(error);

  assert.equal(isReadOnlyError(error), true);
  assert.equal(result.status, READ_ONLY_HTTP_STATUS);
  assert.equal(result.body.success, false);
  assert.equal(result.body.read_only, true);
  assert.match(result.body.message, /chỉ xem/);
});

test('assertWritableConnection chặn ghi khi connection là replica', () => {
  assert.doesNotThrow(() => assertWritableConnection({ __readOnly: false }));
  assert.throws(
    () => assertWritableConnection({ __readOnly: true }),
    { code: 'READ_ONLY_MODE' },
  );
});
