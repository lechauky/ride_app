const repository = require('./trips.repository');
const { validateCreateTripPayload, validateHistoryParams } = require('./trips.validator');

async function createTrip(payload) {
  const validation = validateCreateTripPayload(payload);
  if (!validation.valid) {
    return {
      status: 400,
      body: { success: false, message: validation.errors.join(', ') },
    };
  }

  const trip = await repository.createTrip(validation.normalized);

  return {
    status: 201,
    body: {
      success: true,
      message: 'Đặt chuyến thành công',
      data: trip,
    },
  };
}

async function getTripHistoryByUserId(userId, query) {
  const validation = validateHistoryParams(userId, query);
  if (!validation.valid) {
    return {
      status: 400,
      body: { success: false, message: validation.errors.join(', ') },
    };
  }

  const history = await repository.getTripHistoryByUserId(validation.normalized);

  return {
    status: 200,
    body: {
      success: true,
      message: `Lấy lịch sử chuyến đi thành công (${history.length} chuyến)`,
      data: history,
    },
  };
}

module.exports = {
  createTrip,
  getTripHistoryByUserId,
};
