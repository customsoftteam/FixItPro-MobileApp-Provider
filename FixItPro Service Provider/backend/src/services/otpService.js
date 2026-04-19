const bcrypt = require('bcryptjs');

const generateOtp = () => Math.floor(100000 + Math.random() * 900000).toString();

const hashOtp = async (otp) => bcrypt.hash(otp, 10);

const compareOtp = async (plainOtp, hashedOtp) => bcrypt.compare(plainOtp, hashedOtp);

module.exports = {
  generateOtp,
  hashOtp,
  compareOtp,
};
