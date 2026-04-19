import 'package:flutter/material.dart';

import '../models/product_catalog_item.dart';
import '../services/products_service.dart';
import 'product_details_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductsService _productsService = ProductsService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<ProductCatalogItem> _products = <ProductCatalogItem>[];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({bool silent = false}) async {
    setState(() {
      if (silent) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _error = null;
    });

    try {
      final data = await _productsService.getProductsWithComponents();
      if (!mounted) {
        return;
      }

      setState(() {
        _products = data.where((item) => item.isActive).toList();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  List<ProductCatalogItem> get _visibleProducts {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) {
      return _products;
    }

    return _products.where((product) {
      final tags = product.tags.join(' ').toLowerCase();
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          tags.contains(query);
    }).toList();
  }

  String _normalizeCurrency(double value) {
    final full = value.toStringAsFixed(0);
    final formatted = full.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
    return 'Rs $formatted';
  }

  int _gridColumns(double width) {
    if (width >= 1400) return 4;
    if (width >= 1080) return 3;
    if (width >= 720) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final pageWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = pageWidth >= 1200
      ? 24.0
      : pageWidth >= 700
        ? 16.0
        : 12.0;

    if (_loading && _products.isEmpty) {
      if (_error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load products. Please check the backend and try again.\n\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
            ),
          ),
        );
      }

      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _loadProducts(silent: true),
      child: ListView(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: 'Search products',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchText.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchText = '';
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                  ),
                ),
                if (_refreshing) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_visibleProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text('No products found for the current search.'),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = _gridColumns(width);
                final itemWidth = columns == 1 ? width : (width - ((columns - 1) * 14)) / columns;

                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: _visibleProducts
                      .map(
                        (product) => SizedBox(
                          width: itemWidth,
                          child: _ProductCard(
                            product: product,
                            currencyLabel: _normalizeCurrency(product.totalPrice),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap, required this.currencyLabel});

  final ProductCatalogItem product;
  final VoidCallback onTap;
  final String currencyLabel;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveProductMediaUrl(product.image);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: _CatalogImage(imageUrl: imageUrl),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${product.componentCount} parts',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currencyLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isEmpty ? 'No description available' : product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(product.category.isEmpty ? 'general' : product.category),
                        backgroundColor: const Color(0xFFF8FAFC),
                        side: const BorderSide(color: Color(0xFFD8E3EF)),
                      ),
                      ...product.tags.take(2).map(
                            (tag) => Chip(
                              label: Text(tag),
                              backgroundColor: const Color(0xFFEAF2FF),
                              side: BorderSide.none,
                            ),
                          ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'View components',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogImage extends StatelessWidget {
  const _CatalogImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 44),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 44),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(label),
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      backgroundColor: Colors.white.withValues(alpha: 0.14),
      side: BorderSide.none,
    );
  }
}

