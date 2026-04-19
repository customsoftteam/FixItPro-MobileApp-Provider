const mongoose = require('mongoose');

const productComponentSchema = new mongoose.Schema(
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
    description: {
      type: String,
      default: '',
      trim: true,
    },
    img: {
      type: String,
      default: '',
      trim: true,
    },
    price: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      required: false,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Index for efficient queries
productComponentSchema.index({ productId: 1, isActive: 1 });

const ProductComponent = mongoose.model('ProductComponent', productComponentSchema);

module.exports = ProductComponent;
