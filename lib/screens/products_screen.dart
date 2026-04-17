import 'package:flutter/material.dart';

import '../models/product_catalog_item.dart';
import '../services/products_service.dart';

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

  int get _totalComponents {
    return _products.fold<int>(0, (sum, product) => sum + product.componentCount);
  }

  String _normalizeCurrency(double value) {
    final full = value.toStringAsFixed(0);
    final formatted = full.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
    return 'Rs $formatted';
  }

  @override
  Widget build(BuildContext context) {
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
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x220F172A),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Products',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Browse the active product catalog and open any product to see its components and pricing.',
                            style: TextStyle(color: Color(0xFFD9E6F7), height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_refreshing)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatChip(label: '${_products.length} products', icon: Icons.inventory_2_outlined),
                    _StatChip(label: '$_totalComponents components', icon: Icons.build_outlined),
                    _StatChip(label: 'Website-style catalog', icon: Icons.view_agenda_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.96),
                    hintText: 'Search by product, category, description, or tag',
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
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                ),
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
                final columns = width >= 1180
                    ? 3
                    : width >= 760
                        ? 2
                        : 1;
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

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final ProductCatalogItem product;

  String _normalizeCurrency(double value) {
    final full = value.toStringAsFixed(0);
    final formatted = full.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
    return 'Rs $formatted';
  }

  Widget _statCard({required String label, required String value, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF0F766E)),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveProductMediaUrl(product.image);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF022C22), Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _HeroImage(imageUrl: imageUrl),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: _HeroDetails(product: product, currencyLabel: _normalizeCurrency(product.totalPrice)),
                          ),
                        ],
                      )
                    else ...[
                      _HeroImage(imageUrl: imageUrl),
                      const SizedBox(height: 16),
                      _HeroDetails(product: product, currencyLabel: _normalizeCurrency(product.totalPrice)),
                    ],
                  ],
                );
              },
            ),
          ),
          if (product.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: const BorderSide(color: Color(0xFFD8E3EF)),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard(label: 'Components', value: '${product.componentCount}', icon: Icons.build_outlined),
              const SizedBox(width: 12),
              _statCard(label: 'Total price', value: _normalizeCurrency(product.totalPrice), icon: Icons.currency_rupee_rounded),
            ],
          ),
          const SizedBox(height: 18),
          Text('Components', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          if (product.components.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text('No active components available for this product.'),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 1100
                    ? 3
                    : width >= 700
                        ? 2
                        : 1;
                final itemWidth = columns == 1 ? width : (width - ((columns - 1) * 12)) / columns;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: product.components
                      .map(
                        (component) => SizedBox(
                          width: itemWidth,
                          child: _ComponentCard(component: component),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _CatalogImage(imageUrl: imageUrl),
      ),
    );
  }
}

class _HeroDetails extends StatelessWidget {
  const _HeroDetails({required this.product, required this.currencyLabel});

  final ProductCatalogItem product;
  final String currencyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.description.isEmpty ? 'No description available' : product.description,
          style: const TextStyle(color: Color(0xFFD8F3F0), height: 1.45),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _DetailChip(label: product.category.isEmpty ? 'general' : product.category),
            _DetailChip(label: '${product.componentCount} components'),
            _DetailChip(label: currencyLabel),
          ],
        ),
      ],
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

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({required this.component});

  final ProductComponentItem component;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveProductMediaUrl(component.image);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: _CatalogImage(imageUrl: imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  component.description.isEmpty ? 'No description available' : component.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee_rounded, color: Color(0xFF0F766E), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      component.price.toStringAsFixed(0),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F766E)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.white.withValues(alpha: 0.16),
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      side: BorderSide.none,
    );
  }
}