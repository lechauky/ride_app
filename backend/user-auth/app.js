const express = require('express');
const cors = require('cors');
const userAuthRoutes = require('./modules/user-auth');

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

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

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
