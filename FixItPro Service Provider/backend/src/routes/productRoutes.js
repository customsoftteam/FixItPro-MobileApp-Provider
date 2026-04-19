const express = require('express');
const {
  getAllProducts,
  getProductById,
  getProductComponents,
  getAllProductsWithComponents,
} = require('../controllers/productController');

const router = express.Router();

// Get all active products
router.get('/', getAllProducts);

// Get all products with their components
router.get('/with-components/all', getAllProductsWithComponents);

// Get components for a specific product
router.get('/:productId/components', getProductComponents);

// Get single product by ID
router.get('/:productId', getProductById);

module.exports = router;
