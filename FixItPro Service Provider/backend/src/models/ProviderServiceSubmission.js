const mongoose = require('mongoose');

const providerServiceChecklistSchema = new mongoose.Schema(
  {
    item: { type: String, required: true },
    satisfied: { type: Boolean, default: false },
    note: { type: String, default: '' },
  },
  { _id: false }
);

const providerServiceDocumentSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    url: { type: String, required: true },
  },
  { _id: false }
);

const providerServiceSubmissionSchema = new mongoose.Schema(
  {
    providerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ServiceProvider',
      required: true,
      index: true,
    },
    serviceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Service',
      required: true,
      index: true,
    },
    serviceName: {
      type: String,
      required: true,
      trim: true,
    },
    status: {
      type: String,
      enum: ['UNDER_REVIEW', 'VERIFIED', 'REJECTED'],
      default: 'UNDER_REVIEW',
      index: true,
    },
    checklist: {
      type: [providerServiceChecklistSchema],
      default: [],
    },
    documents: {
      type: [providerServiceDocumentSchema],
      default: [],
    },
    adminNote: { type: String, default: '' },
    submittedAt: { type: Date, default: Date.now },
    verifiedAt: { type: Date, default: null },
  },
  {
    timestamps: true,
  }
);

providerServiceSubmissionSchema.index({ providerId: 1, serviceId: 1 }, { unique: true });

const ProviderServiceSubmission = mongoose.model(
  'ProviderServiceSubmission',
  providerServiceSubmissionSchema
);

module.exports = ProviderServiceSubmission;
