const mongoose = require('mongoose');

const otpSessionSchema = new mongoose.Schema(
  {
    mobile: { type: String, required: true, unique: true, index: true },
    otpHash: { type: String, required: true },
    expiresAt: { type: Date, required: true },
    attempts: { type: Number, default: 0 },
  },
  { timestamps: true }
);

const OtpSession = mongoose.model('OtpSession', otpSessionSchema);

module.exports = OtpSession;
