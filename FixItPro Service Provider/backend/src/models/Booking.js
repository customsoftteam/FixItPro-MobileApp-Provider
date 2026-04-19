const mongoose = require('mongoose');

const timeSlotSchema = new mongoose.Schema(
  {
    start: { type: String, default: '' },
    end: { type: String, default: '' },
  },
  { _id: false }
);

const geoLocationSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number],
      default: [],
    },
  },
  { _id: false }
);

const addressSchema = new mongoose.Schema(
  {
    fullAddress: { type: String, default: '' },
    city: { type: String, default: '' },
    state: { type: String, default: '' },
    pincode: { type: String, default: '' },
    location: {
      type: geoLocationSchema,
      default: () => ({ type: 'Point', coordinates: [] }),
    },
  },
  { _id: false }
);

const pricingSchema = new mongoose.Schema(
  {
    servicePrice: { type: Number, default: 0 },
    convenienceFee: { type: Number, default: 0 },
    discount: { type: Number, default: 0 },
    totalAmount: { type: Number, default: 0 },
  },
  { _id: false }
);

const paymentSchema = new mongoose.Schema(
  {
    method: { type: String, default: 'cash' },
    status: { type: String, default: 'pending' },
  },
  { _id: false }
);

const ratingSchema = new mongoose.Schema(
  {
    stars: { type: Number, default: null },
    review: { type: String, default: '' },
  },
  { _id: false }
);

const bookingSchema = new mongoose.Schema(
  {
    bookingId: {
      type: String,
      index: true,
      trim: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: false,
      index: true,
    },
    serviceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Service',
      required: false,
      index: true,
    },
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: false,
      default: null,
    },
    providerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ServiceProvider',
      required: false,
      default: null,
      index: true,
    },
    scheduledDate: {
      type: Date,
      required: false,
      index: true,
    },
    timeSlot: {
      type: timeSlotSchema,
      default: () => ({ start: '', end: '' }),
    },
    address: {
      type: addressSchema,
      default: () => ({}),
    },
    pricing: {
      type: pricingSchema,
      default: () => ({}),
    },
    status: {
      type: String,
      enum: [
        'pending',            // user booked, waiting for admin
        'assigned',           // admin assigned provider
        'accepted',           // provider accepted booking
        'rejected',           // provider rejected
        'in_progress',        // provider started work
        'paused',             // provider paused ongoing work
        'otp_sent',           // completion OTP sent
        'completed',          // user verified OTP
        'cancelled'           // booking cancelled
      ],
      default: 'pending',
      index: true,
    },
    serviceStartTime: { type: Date },
    serviceEndTime: { type: Date },
    pausedDurationSeconds: {
      type: Number,
      default: 0,
    },
    pauseStartedAt: {
      type: Date,
      default: null,
    },
    completedSteps: {
      type: [Number], // store order/index of completed steps
      default: [],
    },
    demoOtp: {
      type: String,
      default: null,
    },
    otpRequestedAt: {
      type: Date,
      default: null,
    },
    payment: {
      type: paymentSchema,
      default: () => ({}),
    },
    rating: {
      type: ratingSchema,
      default: () => ({}),
    },
    notes: {
      type: String,
      default: '',
    },

    // Legacy compatibility fields from earlier app shape.
    serviceType: { type: String, default: '' },
    customerName: { type: String, default: '' },
    customerAddress: { type: String, default: '' },
    scheduledAt: { type: Date, required: false },
    amount: { type: Number, default: 0 },

    // New: serviceSteps (array of strings or objects, default empty array)
    serviceSteps: {
      type: [mongoose.Schema.Types.Mixed],
      default: [],
    },
  },
  { timestamps: true }
);

const Booking = mongoose.model('Booking', bookingSchema);

module.exports = Booking;
