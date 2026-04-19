const mongoose = require('mongoose');

const availabilitySchema = new mongoose.Schema(
  {
    workingDays: {
      type: [
        {
          type: String,
          enum: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
        },
      ],
      default: [],
    },
    slots: {
      type: [
        {
          start: { type: String, required: true },
          end: { type: String, required: true },
        },
      ],
      default: [],
    },
    status: {
      type: String,
      enum: ['AVAILABLE', 'BUSY', 'OFFLINE'],
      default: 'AVAILABLE',
    },
  },
  { _id: false }
);

const serviceProviderSchema = new mongoose.Schema(
  {
    mobile: { type: String, required: true, unique: true, index: true },
    name: { type: String, default: '' },
    email: { type: String, default: '' },
    dob: { type: Date },
    gender: {
      type: String,
      enum: ['MALE', 'FEMALE', 'OTHER', ''],
      default: '',
    },
    expertise: {
      type: [String],
      default: [],
    },
    experience: {
      type: String,
      enum: ['MORE_THAN_1_YEAR', 'SIX_TO_TWELVE_MONTHS', 'LESS_THAN_6_MONTHS', 'NO_EXPERIENCE', ''],
      default: '',
    },
    maritalStatus: {
      type: String,
      enum: ['MARRIED', 'UNMARRIED', ''],
      default: '',
    },
    emergencyContact: { type: String, default: '' },
    referralName: { type: String, default: '' },
    hasVehicle: { type: Boolean, default: false },
    vehicleDetails: {
      type: {
        type: String,
        default: '',
      },
      model: { type: String, default: '' },
      registrationNumber: { type: String, default: '' },
    },
    status: {
      type: String,
      enum: ['INACTIVE', 'ACTIVE', 'BUSY', 'AVAILABLE'],
      default: 'INACTIVE',
      index: true,
    },
    location: {
      latitude: { type: Number },
      longitude: { type: Number },
    },
    documents: {
      aadharNumber: { type: String, default: '' },
      aadharFrontUrl: { type: String, default: '' },
      aadharBackUrl: { type: String, default: '' },
      panNumber: { type: String, default: '' },
      panUrl: { type: String, default: '' },
      chequeUrl: { type: String, default: '' },
    },
    bankDetails: {
      accountHolderName: { type: String, default: '' },
      bankName: { type: String, default: '' },
      accountNumber: { type: String, default: '' },
      ifscCode: { type: String, default: '' },
      branchName: { type: String, default: '' },
    },
    skills: {
      type: [String],
      default: [],
    },
    availability: {
      type: availabilitySchema,
      default: () => ({ workingDays: [], slots: [] }),
    },
    profileImage: {
      type: String,
      default: '',
    },
    onboardingCompleted: { type: Boolean, default: false },
  },
  {
    timestamps: true,
  }
);

const ServiceProvider = mongoose.model('ServiceProvider', serviceProviderSchema);

module.exports = ServiceProvider;
