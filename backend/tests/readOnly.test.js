const test = require('node:test');
const assert = require('node:assert/strict');
const { isWriteQuery } = require('../config/database');
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
