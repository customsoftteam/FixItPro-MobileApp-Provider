const jwt = require('jsonwebtoken');
const ServiceProvider = require('../models/ServiceProvider');

let io = null;

const providerRoom = (providerId) => `provider:${String(providerId)}`;

const defaultOrigins = ['http://localhost:5173', 'http://localhost:5174', 'http://localhost:5175'];
const configuredOrigins = [process.env.CLIENT_URL, process.env.CLIENT_URLS]
  .filter(Boolean)
  .flatMap((value) =>
    String(value)
      .split(',')
      .map((origin) => origin.trim().replace(/\/$/, ''))
      .filter(Boolean)
  );

const allowedOrigins = new Set([...defaultOrigins, ...configuredOrigins]);

const validateOrigin = (origin, callback) => {
  if (!origin) return callback(null, true);

  const normalizedOrigin = String(origin).trim().replace(/\/$/, '');
  if (allowedOrigins.has(normalizedOrigin)) {
    return callback(null, true);
  }

  return callback(new Error(`CORS blocked for origin ${origin}`));
};

const initializeSocket = (server) => {
  const { Server } = require('socket.io');

  io = new Server(server, {
    cors: {
      origin: validateOrigin,
      credentials: true,
    },
  });

  io.use(async (socket, next) => {
    try {
      const authHeader = socket.handshake.auth?.token || socket.handshake.headers?.authorization || '';
      const raw = String(authHeader).startsWith('Bearer ') ? String(authHeader).split(' ')[1] : String(authHeader);

      if (!raw) {
        return next(new Error('Unauthorized'));
      }

      const decoded = jwt.verify(raw, process.env.JWT_SECRET);
      const provider = await ServiceProvider.findById(decoded.providerId).select('_id');

      if (!provider) {
        return next(new Error('Unauthorized'));
      }

      socket.providerId = String(provider._id);
      return next();
    } catch (_error) {
      return next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    socket.join(providerRoom(socket.providerId));

    socket.on('notification:read-all', () => {
      io.to(providerRoom(socket.providerId)).emit('notification:read-all:ack');
    });
  });

  return io;
};

const getIO = () => io;

const emitToProvider = (providerId, event, payload) => {
  if (!io || !providerId) return;
  io.to(providerRoom(providerId)).emit(event, payload);
};

module.exports = {
  initializeSocket,
  getIO,
  emitToProvider,
  providerRoom,
};
