const express = require('express');
const controller = require('./trips.controller');
const authMiddleware = require('../../middleware/authMiddleware');

const router = express.Router();

router.post('/', authMiddleware, controller.createTrip);
router.get('/pending/nearest', authMiddleware, controller.getNearestPendingTrips);
router.get('/history/:userId', authMiddleware, controller.getTripHistoryByUserId);
router.post('/:tripId/accept', authMiddleware, controller.acceptTrip);
router.post('/:tripId/reject', authMiddleware, controller.rejectTrip);
router.post('/:tripId/complete', authMiddleware, controller.completeTrip);

module.exports = router;
