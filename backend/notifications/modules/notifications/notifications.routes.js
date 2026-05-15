const express = require('express');
const controller = require('./notifications.controller');
const authMiddleware = require('../../../user-auth/middleware/authMiddleware');

const router = express.Router();

router.get('/', authMiddleware, controller.getNotifications);
router.put('/read-all', authMiddleware, controller.markAllRead);
router.put('/:notificationId/read', authMiddleware, controller.markRead);
router.delete('/:notificationId', authMiddleware, controller.softDelete);

module.exports = router;
