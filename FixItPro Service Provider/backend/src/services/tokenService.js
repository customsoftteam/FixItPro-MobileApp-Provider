const jwt = require('jsonwebtoken');

const generateToken = (provider) => {
  const jwtSecret = process.env.JWT_SECRET;

  if (!jwtSecret) {
    throw new Error('JWT_SECRET is not configured in environment variables');
  }

  return jwt.sign(
    {
      providerId: provider._id,
      mobile: provider.mobile,
    },
    jwtSecret,
    { expiresIn: process.env.JWT_EXPIRES_IN || '1d' }
  );
};

module.exports = { generateToken };
