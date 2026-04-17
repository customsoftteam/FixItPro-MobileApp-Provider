import '../models/product_catalog_item.dart';
import 'api_client.dart';

class ProductsService {
  ProductsService._();

  static final ProductsService instance = ProductsService._();

  Future<List<ProductCatalogItem>> getProductsWithComponents() async {
    final response = await ApiClient.instance.get('/products/with-components/all');
    final products = (response['products'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _mapProduct(Map<String, dynamic>.from(item)))
        .toList();

    return products;
  }

  ProductCatalogItem _mapProduct(Map<String, dynamic> data) {
    final components = (data['components'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _mapComponent(Map<String, dynamic>.from(item)))
        .toList();

    return ProductCatalogItem(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      slug: data['slug']?.toString() ?? '',
      name: data['name']?.toString().isNotEmpty == true ? data['name'].toString() : 'Product',
      image: data['image']?.toString().isNotEmpty == true ? data['image'].toString() : data['img']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      tags: (data['tags'] as List? ?? const []).map((tag) => tag.toString()).toList(),
      isActive: data['isActive'] == true,
      components: components,
    );
  }

  ProductComponentItem _mapComponent(Map<String, dynamic> data) {
    return ProductComponentItem(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      name: data['name']?.toString().isNotEmpty == true ? data['name'].toString() : 'Component',
      description: data['description']?.toString() ?? '',
      image: data['img']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

String resolveProductMediaUrl(String value) {
  final image = value.trim();
  if (image.isEmpty) {
    return '';
  }

  final parsed = Uri.tryParse(image);
  if (parsed != null && parsed.hasScheme) {
    return image;
  }

  final base = Uri.parse(ApiClient.instance.baseUrl);
  final origin = base.replace(path: '');
  final normalized = image.startsWith('/') ? image : '/$image';
  return origin.resolve(normalized).toString();
}