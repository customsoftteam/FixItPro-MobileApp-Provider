import 'package:flutter/material.dart';

import '../models/product_catalog_item.dart';
import '../services/products_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveProductMediaUrl(product.image);
    final pageWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = pageWidth >= 1200
        ? 24.0
        : pageWidth >= 700
            ? 16.0
            : 12.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 16),
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _CatalogImage(imageUrl: imageUrl),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            product.description.isEmpty ? 'No description available' : product.description,
            style: const TextStyle(color: Color(0xFF475569), height: 1.45),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(
                label: Text(product.category.isEmpty ? 'general' : product.category),
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: Color(0xFFD8E3EF)),
              ),
              Chip(
                label: Text('${product.componentCount} components'),
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: Color(0xFFD8E3EF)),
              ),
              Chip(
                label: Text(_normalizeCurrency(product.totalPrice)),
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: Color(0xFFD8E3EF)),
              ),
            ],
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

