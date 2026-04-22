require('dotenv').config();
const createApp = require('./app');

const app = createApp();
const port = process.env.PORT || 5001;

app.listen(port, () => {
  console.log(`Auth backend running on port ${port}`);
});
