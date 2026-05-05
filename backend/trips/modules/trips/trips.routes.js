const express = require('express');
const controller = require('./trips.controller');
const authMiddleware = require('../../middleware/authMiddleware');

const router = express.Router();

router.post('/', authMiddleware, controller.createTrip);
router.get('/history/:userId', authMiddleware, controller.getTripHistoryByUserId);

module.exports = router;
