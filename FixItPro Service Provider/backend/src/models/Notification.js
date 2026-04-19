const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    providerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ServiceProvider',
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: ['BOOKING_ASSIGNED', 'BOOKING_UPDATED', 'GENERAL'],
      default: 'GENERAL',
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    message: {
      type: String,
      required: true,
      trim: true,
    },
    meta: {
      bookingId: { type: String, default: '' },
      bookingObjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', default: null },
      status: { type: String, default: '' },
    },
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },
    readAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Notification', notificationSchema);
