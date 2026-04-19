const jwt = require('jsonwebtoken');
const ServiceProvider = require('../models/ServiceProvider');
const ApiError = require('../utils/apiError');
const asyncHandler = require('../utils/asyncHandler');

const protect = asyncHandler(async (req, res, next) => {
  const authHeader = req.headers.authorization || '';

  if (!authHeader.startsWith('Bearer ')) {
    throw new ApiError(401, 'Unauthorized: token missing');
  }

  const token = authHeader.split(' ')[1];
  const decoded = jwt.verify(token, process.env.JWT_SECRET);

  const provider = await ServiceProvider.findById(decoded.providerId);
  if (!provider) {
    throw new ApiError(401, 'Unauthorized: user not found');
  }

  req.provider = provider;
  next();
});

module.exports = { protect };
