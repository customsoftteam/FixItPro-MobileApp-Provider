const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    slug: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
      index: true,
    },
    image: {
      type: String,
      default: '',
      trim: true,
    },
    img: {
      type: String,
      default: '',
      trim: true,
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    category: {
      type: String,
      default: '',
      trim: true,
      lowercase: true,
    },
    tags: {
      type: [String],
      default: [],
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

productSchema.index({ slug: 1 }, { unique: true });

const Product = mongoose.model('Product', productSchema);

module.exports = Product;
