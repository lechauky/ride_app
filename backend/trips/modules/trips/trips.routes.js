const express = require('express');
const controller = require('./trips.controller');
const authMiddleware = require('../../middleware/authMiddleware');

const router = express.Router();

router.post('/', authMiddleware, controller.createTrip);
router.get('/pending/nearest', authMiddleware, controller.getNearestPendingTrips);
router.get('/history/:userId', authMiddleware, controller.getTripHistoryByUserId);
router.get('/:tripId/details', authMiddleware, controller.getTripDetails);
router.post('/:tripId/accept', authMiddleware, controller.acceptTrip);
router.post('/:tripId/reject', authMiddleware, controller.rejectTrip);
router.post('/:tripId/complete', authMiddleware, controller.completeTrip);
router.post('/:tripId/rating', authMiddleware, controller.saveRating);

module.exports = router;
