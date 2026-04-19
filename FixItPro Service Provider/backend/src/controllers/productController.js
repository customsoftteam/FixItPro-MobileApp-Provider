const Product = require('../models/Product');
const ProductComponent = require('../models/ProductComponent');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');

/**
 * Get all active products
 */
exports.getAllProducts = asyncHandler(async (req, res) => {
  try {
    const products = await Product.find({ isActive: true })
      .select('-createdBy -updatedAt -__v')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      products: products || [],
    });
  } catch (error) {
    throw new ApiError(500, 'Error fetching products');
  }
});

/**
 * Get single product by ID
 */
exports.getProductById = asyncHandler(async (req, res) => {
  try {
    const { productId } = req.params;

    const product = await Product.findById(productId).select('-createdBy -__v');

    if (!product || !product.isActive) {
      throw new ApiError(404, 'Product not found');
    }

    res.status(200).json({
      success: true,
      product,
    });
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }
    throw new ApiError(500, 'Error fetching product');
  }
});

/**
 * Get components for a specific product
 */
exports.getProductComponents = asyncHandler(async (req, res) => {
  try {
    const { productId } = req.params;

    // Verify product exists
    const product = await Product.findById(productId);
    if (!product || !product.isActive) {
      throw new ApiError(404, 'Product not found');
    }

    const components = await ProductComponent.find({
      productId,
      isActive: true,
    })
      .select('-createdBy -__v')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      components: components || [],
    });
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }
    throw new ApiError(500, 'Error fetching product components');
  }
});

/**
 * Get all products with their components
 */
exports.getAllProductsWithComponents = asyncHandler(async (req, res) => {
  try {
    const products = await Product.find({ isActive: true })
      .select('-createdBy -updatedAt -__v')
      .sort({ createdAt: -1 });

    const productsWithComponents = await Promise.all(
      products.map(async (product) => {
        const components = await ProductComponent.find({
          productId: product._id,
          isActive: true,
        })
          .select('-createdBy -__v')
          .sort({ createdAt: -1 });

        return {
          ...product.toObject(),
          components: components || [],
        };
      })
    );

    res.status(200).json({
      success: true,
      products: productsWithComponents,
    });
  } catch (error) {
    throw new ApiError(500, 'Error fetching products with components');
  }
});
