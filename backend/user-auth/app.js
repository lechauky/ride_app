const express = require('express');
const cors = require('cors');
const userAuthRoutes = require('./modules/user-auth');

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get('/api/health', (req, res) => {
    res.json({ success: true, message: 'Backend is running' });
  });

  app.use('/api/auth', userAuthRoutes);

  return app;
}

module.exports = createApp;
