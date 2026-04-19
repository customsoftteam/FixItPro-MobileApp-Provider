const twilio = require('twilio');

// Development override: keep OTP verification in dummy mode.
const isMockModeEnabled = () => true;

const getEnv = (key) => String(process.env[key] || '').trim();

const isTwilioConfigured = () => {
  return Boolean(
    getEnv('TWILIO_ACCOUNT_SID') &&
      getEnv('TWILIO_AUTH_TOKEN') &&
      getEnv('TWILIO_VERIFY_SERVICE_SID')
  );
};

const validateTwilioConfig = () => {
  const accountSid = getEnv('TWILIO_ACCOUNT_SID');
  const verifyServiceSid = getEnv('TWILIO_VERIFY_SERVICE_SID');

  if (!accountSid.startsWith('AC')) {
    throw new Error('Invalid TWILIO_ACCOUNT_SID. It should start with AC.');
  }

  if (!verifyServiceSid.startsWith('VA')) {
    throw new Error(
      'Invalid TWILIO_VERIFY_SERVICE_SID. It should start with VA (Verify Service SID), not Messaging Service SID.'
    );
  }
};

const getTwilioClient = () => {
  if (!isTwilioConfigured()) {
    return null;
  }

  validateTwilioConfig();

  return twilio(getEnv('TWILIO_ACCOUNT_SID'), getEnv('TWILIO_AUTH_TOKEN'));
};

const sendOtpSms = async (phoneNumber) => {
  const client = getTwilioClient();

  if (!client) {
    if (isMockModeEnabled()) {
      return { sid: 'dev-otp', status: 'pending', channel: 'sms' };
    }

    throw new Error(
      'Twilio is not configured. Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN and TWILIO_VERIFY_SERVICE_SID.'
    );
  }

  const verification = await client.verify.v2
    .services(getEnv('TWILIO_VERIFY_SERVICE_SID'))
    .verifications.create({
      to: phoneNumber,
      channel: 'sms',
    });

  return verification;
};

const verifyOtpCode = async (phoneNumber, code) => {
  const client = getTwilioClient();

  if (!client) {
    if (isMockModeEnabled()) {
      return {
        status: code === '123456' ? 'approved' : 'pending',
      };
    }

    throw new Error(
      'Twilio is not configured. Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN and TWILIO_VERIFY_SERVICE_SID.'
    );
  }

  const verificationCheck = await client.verify.v2
    .services(getEnv('TWILIO_VERIFY_SERVICE_SID'))
    .verificationChecks.create({
      to: phoneNumber,
      code,
    });

  return verificationCheck;
};

module.exports = {
  sendOtpSms,
  verifyOtpCode,
  isMockModeEnabled,
};
