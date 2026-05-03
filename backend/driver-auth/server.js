require('dotenv').config();
const createApp = require('./app');

const app = createApp();
const port = process.env.PORT || 3001;

app.listen(port, () => {
  console.log(`Driver Auth backend running on port ${port}`);
});
