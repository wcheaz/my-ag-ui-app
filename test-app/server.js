const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Health endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Basic endpoint for testing
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'Test application running',
    health: '/api/health'
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Test app listening at http://0.0.0.0:${port}`);
});