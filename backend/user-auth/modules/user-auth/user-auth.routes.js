const express = require('express');
const controller = require('./user-auth.controller');
const authMiddleware = require('./user-auth.middleware');

const router = express.Router();

router.post('/register', controller.register);
router.post('/login', controller.login);
router.get('/me', authMiddleware, controller.me);

module.exports = router;
