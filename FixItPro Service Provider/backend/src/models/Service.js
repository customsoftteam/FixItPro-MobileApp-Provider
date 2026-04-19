const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema(
  {
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    img: {
      type: String,
      default: '',
      trim: true,
    },
    video: {
      type: String,
      default: '',
      trim: true,
    },
    price: {
      type: Number,
      default: 0,
    },
    duration: {
      type: Number,
      default: 0,
    },
    // steps is not required in your sample, but keep for compatibility
    steps: {
      type: [
        {
          title: { type: String },
          description: { type: String, default: '' },
          order: { type: Number },
        },
      ],
      default: [],
    },
    process: {
      type: Object,
      default: {},
    },
    checklist: {
      type: [String],
      default: [],
    },
    requiredDocuments: {
      type: [String],
      default: [],
    },
    timeSlots: {
      type: Object,
      default: {},
    },
    note: {
      type: String,
      default: '',
      trim: true,
    },
    ratings: {
      type: Number,
      default: 0,
    },
    description: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

const Service = mongoose.model('Service', serviceSchema);

module.exports = Service;
