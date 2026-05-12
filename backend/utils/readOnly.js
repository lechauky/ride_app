const READ_ONLY_HTTP_STATUS = 503;
const READ_ONLY_MESSAGE = 'Server chính đang bảo trì, hiện chỉ xem được dữ liệu';

function isReadOnlyError(error) {
  if (!error) return false;
  if (error.code === 'READ_ONLY_MODE') return true;

  const message = String(error.message || '').toLowerCase();
  return (
    message.includes('read-only') ||
    message.includes('read only') ||
    message.includes('chỉ xem')
  );
}

function buildReadOnlyResponse() {
  return {
    success: false,
    read_only: true,
    message: READ_ONLY_MESSAGE,
  };
}

function mapReadOnlyResult(error) {
  if (!isReadOnlyError(error)) return null;
  return {
    status: READ_ONLY_HTTP_STATUS,
    body: buildReadOnlyResponse(),
  };
}

module.exports = {
  READ_ONLY_HTTP_STATUS,
  READ_ONLY_MESSAGE,
  isReadOnlyError,
  buildReadOnlyResponse,
  mapReadOnlyResult,
};
