const express = require('express');
const authRoutes = require('./authRoutes');
const providerRoutes = require('./providerRoutes');
const bookingRoutes = require('./bookingRoutes');
const notificationRoutes = require('./notificationRoutes');
const productRoutes = require('./productRoutes');

const router = express.Router();

router.get('/health', (req, res) => {
  res.json({ message: 'API is healthy' });
});

router.use('/auth', authRoutes);
router.use('/providers', providerRoutes);
router.use('/bookings', bookingRoutes);
router.use('/notifications', notificationRoutes);
router.use('/products', productRoutes);

module.exports = router;
