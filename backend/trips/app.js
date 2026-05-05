const express = require('express');
const cors = require('cors');
const tripsRoutes = require('./modules/trips');

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get('/api/health', (req, res) => {
    res.json({ success: true, message: 'Trips backend is running' });
  });

  app.use('/api/trips', tripsRoutes);

  app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: process.env.NODE_ENV === 'development' ? err.message : undefined,
    });
  });

  return app;
}

module.exports = createApp;
