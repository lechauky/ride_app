const express = require('express');
const cors = require('cors');
const driverAuthRoutes = require('./modules/driver-auth/driver-auth.routes');

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get('/api/health', (req, res) => {
    res.json({ success: true, message: 'Driver Auth Backend is running' });
  });

  // Routes
  app.use('/api/drivers', driverAuthRoutes);

  // Error handler
  app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
      success: false, 
      message: 'Internal Server Error',
      error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
  });

  return app;
}

module.exports = createApp;
