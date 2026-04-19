const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    mobile: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    name: {
      type: String,
      default: '',
      trim: true,
    },
    email: {
      type: String,
      default: '',
      trim: true,
      lowercase: true,
      index: true,
    },
    lastLoginAt: {
      type: Date,
      default: null,
    },
    location: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    isVerified: {
      type: Boolean,
      default: false,
      index: true,
    },
    profileImage: {
      type: String,
      default: '',
      trim: true,
    },
    role: {
      type: String,
      default: 'user',
      trim: true,
      lowercase: true,
    },
  },
  {
    timestamps: true,
  }
);

userSchema.index({ mobile: 1 }, { unique: true });

const User = mongoose.model('User', userSchema);

module.exports = User;
