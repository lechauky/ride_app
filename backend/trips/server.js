require('dotenv').config();
const createApp = require('./app');

const app = createApp();
const port = process.env.TRIPS_PORT || 3002;

app.listen(port, () => {
  console.log(`Trips backend running on port ${port}`);
});
