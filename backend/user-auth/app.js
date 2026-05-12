const express = require('express');
const cors = require('cors');
const userAuthRoutes = require('./modules/user-auth');
const { READ_ONLY_HTTP_STATUS, buildReadOnlyResponse } = require('../utils/readOnly');

// Mount thêm routes từ các service khác để chạy chung 1 port
let tripsRoutes, driverAuthRoutes, notificationsRoutes;
try {
  tripsRoutes = require('../trips/modules/trips');
} catch (e) {
  console.warn('Trips routes not found, skipping...');
}
try {
  driverAuthRoutes = require('../driver-auth/modules/driver-auth/driver-auth.routes');
} catch (e) {
  console.warn('Driver-auth routes not found, skipping...');
}
try {
  notificationsRoutes = require('../notifications/modules/notifications');
} catch (e) {
  console.warn('Notifications routes not found, skipping...');
}

function createApp(apiPort = process.env.PORT) {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.use((req, res, next) => {
    const port = Number(apiPort || req.socket.localPort);
    const isBackupPort = port === 6001 || port === 6002;
    const isWriteMethod = ['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method);
    if (isBackupPort && isWriteMethod) {
      return res.status(READ_ONLY_HTTP_STATUS).json(buildReadOnlyResponse());
    }
    return next();
  });

  app.get('/api/health', (req, res) => {
    res.json({ success: true, message: 'Backend is running' });
  });

  app.use('/api/auth', userAuthRoutes);

  if (tripsRoutes) {
    app.use('/api/trips', tripsRoutes);
  }

  if (driverAuthRoutes) {
    app.use('/api/drivers', driverAuthRoutes);
  }

  if (notificationsRoutes) {
    app.use('/api/notifications', notificationsRoutes);
  }

  return app;
}

module.exports = createApp;
