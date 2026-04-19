const Notification = require('../models/Notification');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');

const listNotifications = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const parsedPage = Math.max(1, Number(page) || 1);
  const parsedLimit = Math.min(50, Math.max(1, Number(limit) || 20));
  const skip = (parsedPage - 1) * parsedLimit;

  const providerId = req.provider._id;

  const [notifications, total, unreadCount] = await Promise.all([
    Notification.find({ providerId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parsedLimit),
    Notification.countDocuments({ providerId }),
    Notification.countDocuments({ providerId, isRead: false }),
  ]);

  res.json({
    notifications,
    unreadCount,
    pagination: {
      page: parsedPage,
      limit: parsedLimit,
      total,
      pages: Math.ceil(total / parsedLimit),
    },
  });
});

const markNotificationRead = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const notification = await Notification.findOne({
    _id: id,
    providerId: req.provider._id,
  });

  if (!notification) {
    throw new ApiError(404, 'Notification not found');
  }

  if (!notification.isRead) {
    notification.isRead = true;
    notification.readAt = new Date();
    await notification.save();
  }

  res.json({ notification });
});

const markAllNotificationsRead = asyncHandler(async (req, res) => {
  await Notification.updateMany(
    {
      providerId: req.provider._id,
      isRead: false,
    },
    {
      $set: {
        isRead: true,
        readAt: new Date(),
      },
    }
  );

  res.json({ message: 'All notifications marked as read' });
});

module.exports = {
  listNotifications,
  markNotificationRead,
  markAllNotificationsRead,
};
