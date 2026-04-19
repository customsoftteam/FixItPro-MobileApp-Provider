const Notification = require('../models/Notification');
const { emitToProvider } = require('./socketService');

const createNotification = async ({
  providerId,
  type = 'GENERAL',
  title,
  message,
  meta = {},
}) => {
  if (!providerId || !title || !message) return null;

  const notification = await Notification.create({
    providerId,
    type,
    title,
    message,
    meta,
  });

  emitToProvider(providerId, 'notification:new', {
    notification,
  });

  return notification;
};

module.exports = {
  createNotification,
};
