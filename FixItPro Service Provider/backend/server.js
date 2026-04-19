const app = require('./app');
const http = require('http');
const connectDB = require('./src/config/db');
const { initializeSocket } = require('./src/services/socketService');

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    await connectDB();
    const server = http.createServer(app);
    initializeSocket(server);

    server.on('error', (error) => {
      if (error.code === 'EADDRINUSE') {
        console.error(`Port ${PORT} is already in use. Stop the existing backend process and try again.`);
        process.exit(1);
      }

      console.error('Server startup error:', error.message);
      process.exit(1);
    });

    server.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();
