const repository = require('./trips.repository');
const {
  validateCreateTripPayload,
  validateHistoryParams,
  validatePendingTripsParams,
  validateRatingPayload,
  validateTripActionPayload,
} = require('./trips.validator');

function mapActionError(error) {
  if (error.code === 'DRIVER_NOT_FOUND') return 404;
  if (error.code === 'TRIP_NOT_FOUND') return 404;
  if (error.code === 'TRIP_NOT_AVAILABLE') return 409;
  return 500;
}

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

async function getNearestPendingTrips(query, user) {
  const validation = validatePendingTripsParams(query);
  if (!validation.valid) {
    return {
      status: 400,
      body: { success: false, message: validation.errors.join(', ') },
    };
  }

  const trips = await repository.getNearestPendingTrips({
    ...validation.normalized,
    driverUserId: user?.id || null,
  });

  return {
    status: 200,
    body: {
      success: true,
      message: trips.length
        ? `Tìm thấy ${trips.length} chuyến đang chờ`
        : 'Không có chuyến đang chờ',
      data: trips,
    },
  };
}

async function acceptTrip(tripId, user, body) {
  const validation = validateTripActionPayload(tripId, user, body);
  if (!validation.valid) {
    return {
      status: 400,
      body: { success: false, message: validation.errors.join(', ') },
    };
  }

  try {
    const result = await repository.acceptTrip(validation.normalized);
    return {
      status: 200,
      body: {
        success: true,
        message: 'Nhận chuyến thành công',
        data: result,
      },
    };
  } catch (error) {
    return {
      status: mapActionError(error),
      body: { success: false, message: error.message },
    };
  }
}

async function rejectTrip(tripId, user, body) {
  const validation = validateTripActionPayload(tripId, user, body);
  if (!validation.valid) {
    return {
      status: 400,
      body: { success: false, message: validation.errors.join(', ') },
    };
  }

  try {
    const result = await repository.rejectTrip(validation.normalized);
    return {
      status: 200,
      body: {
        success: true,
        message: 'Từ chối chuyến thành công',
        data: result,
      },
    };
  } catch (error) {
    return {
      status: mapActionError(error),
      body: { success: false, message: error.message },
    };
  }
}

async function completeTrip(tripId, user, body) {
  const validation = validateTripActionPayload(tripId, user, body);
  if (!validation.valid) {
    return {
      status: 400,
      body: { success: false, message: validation.errors.join(', ') },
    };
  }

  try {
    const result = await repository.completeTrip(validation.normalized);
    return {
      status: 200,
      body: {
        success: true,
        message: 'Hoàn thành chuyến thành công',
        data: result,
      },
    };
  } catch (error) {
    return {
      status: mapActionError(error),
      body: { success: false, message: error.message },
    };
  }
}

async function saveRating(tripId, user, body) {
  const validation = validateRatingPayload(tripId, user, body);
  if (!validation.valid) {
    return {
      status: 400,
      body: { success: false, message: validation.errors.join(', ') },
    };
  }

  const rating = await repository.saveRating(validation.normalized);

  return {
    status: 200,
    body: {
      success: true,
      message: 'Lưu đánh giá thành công',
      data: rating,
    },
  };
}

module.exports = {
  createTrip,
  getTripHistoryByUserId,
  getNearestPendingTrips,
  acceptTrip,
  rejectTrip,
  completeTrip,
  saveRating,
};
