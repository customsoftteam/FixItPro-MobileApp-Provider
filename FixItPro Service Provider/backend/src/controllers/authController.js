const ServiceProvider = require('../models/ServiceProvider');
const { generateToken } = require('../services/tokenService');
const { sendOtpSms, verifyOtpCode, isMockModeEnabled } = require('../services/twilioOtpService');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');

const mobileRegex = /^[6-9]\d{9}$/;
const toE164IndiaNumber = (mobile) => `+91${mobile}`;

const sendOtp = asyncHandler(async (req, res) => {
  const { mobile } = req.body;

  if (!mobile || !mobileRegex.test(mobile)) {
    throw new ApiError(400, 'Valid mobile number is required');
  }

  const e164PhoneNumber = toE164IndiaNumber(mobile);

  try {
    await sendOtpSms(e164PhoneNumber);
  } catch (error) {
    throw new ApiError(500, error.message || 'Failed to send OTP');
  }

  res.json({
    message: 'OTP sent successfully',
    ...(isMockModeEnabled() ? { debugOtp: '123456' } : {}),
  });
});

const verifyOtp = asyncHandler(async (req, res) => {
  const { mobile, otp } = req.body;

  if (!mobile || !mobileRegex.test(mobile)) {
    throw new ApiError(400, 'Valid mobile number is required');
  }

  if (!otp || String(otp).length !== 6) {
    throw new ApiError(400, 'Valid 6 digit OTP is required');
  }

  const e164PhoneNumber = toE164IndiaNumber(mobile);

  let verificationResult;
  try {
    verificationResult = await verifyOtpCode(e164PhoneNumber, String(otp));
  } catch (error) {
    throw new ApiError(500, error.message || 'OTP verification failed');
  }

  if (verificationResult.status !== 'approved') {
    throw new ApiError(400, 'Invalid OTP');
  }

  let provider = await ServiceProvider.findOne({ mobile });
  let isNewUser = false;

  if (!provider) {
    isNewUser = true;
    provider = await ServiceProvider.create({ mobile, status: 'INACTIVE' });
  } else if (!provider.onboardingCompleted) {
    isNewUser = true;
  }

  const token = generateToken(provider);

  res.json({
    message: 'Login successful',
    token,
    isNewUser,
    provider: {
      id: provider._id,
      mobile: provider.mobile,
      name: provider.name,
      status: provider.status,
      onboardingCompleted: provider.onboardingCompleted,
    },
  });
});

module.exports = {
  sendOtp,
  verifyOtp,
};
