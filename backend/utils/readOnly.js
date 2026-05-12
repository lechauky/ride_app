const READ_ONLY_HTTP_STATUS = 503;
const READ_ONLY_MESSAGE = 'Server chính đang bảo trì, hiện chỉ xem được dữ liệu';
const CONNECTION_ERROR_CODES = new Set([
  'ESOCKET',
  'ECONNREFUSED',
  'ECONNCLOSED',
  'ETIMEOUT',
  'ENOTFOUND',
  'EAI_AGAIN',
]);
const READ_ONLY_PHRASES = [
  'read-only',
  'read only',
  'chỉ xem',
  'failed to connect',
  'connection lost',
  'connect etimedout',
  'connect econnrefused',
  'getaddrinfo enotfound',
];

function isReadOnlyError(error) {
  if (!error) return false;
  if (error.code === 'READ_ONLY_MODE') return true;
  if (CONNECTION_ERROR_CODES.has(error.code)) return true;

  const message = String(error.message || '').toLowerCase();
  return READ_ONLY_PHRASES.some((phrase) => message.includes(phrase));
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
