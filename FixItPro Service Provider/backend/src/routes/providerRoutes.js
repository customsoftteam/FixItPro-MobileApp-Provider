const express = require('express');
const {
  getMyProfile,
  listServices,
  saveBasicDetails,
  saveProfessionalDetails,
  saveDocumentDetails,
  uploadProfileImage,
  saveLocation,
  updateProfile,
  updateSkills,
  updateAvailability,
  getDashboardSummary,
  getLocationAddress,
  getEarningsOverview,
  getEarningsTrend,
  getRevenueByService,
  getRevenueByLocation,
  getTransactionHistory,
  submitServiceForVerification,
} = require('../controllers/providerController');
const { protect } = require('../middlewares/authMiddleware');
const {
  uploadDocuments,
  uploadProfileImage: uploadProfileImageMiddleware,
  uploadServiceDocuments,
} = require('../middlewares/uploadMiddleware');

const router = express.Router();

router.use(protect);

router.get('/me', getMyProfile);
router.get('/services', listServices);
router.get('/dashboard/summary', getDashboardSummary);
router.get('/location/address', getLocationAddress);

// Earnings endpoints
router.get('/earnings/overview', getEarningsOverview);
router.get('/earnings/trend', getEarningsTrend);
router.get('/earnings/by-service', getRevenueByService);
router.get('/earnings/by-location', getRevenueByLocation);
router.get('/earnings/transactions', getTransactionHistory);

router.put('/onboarding/basic', saveBasicDetails);
router.put('/onboarding/professional', saveProfessionalDetails);
router.put('/onboarding/documents', uploadDocuments, saveDocumentDetails);
router.put('/onboarding/location', saveLocation);
router.put('/profile/image', uploadProfileImageMiddleware, uploadProfileImage);
router.post('/services/:serviceId/submit', uploadServiceDocuments, submitServiceForVerification);

router.put('/me', updateProfile);
router.put('/skills', updateSkills);
router.put('/availability', updateAvailability);

module.exports = router;
