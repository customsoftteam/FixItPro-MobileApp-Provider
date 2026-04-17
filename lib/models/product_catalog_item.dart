class ProductCatalogItem {
  const ProductCatalogItem({
    required this.id,
    required this.slug,
    required this.name,
    required this.image,
    required this.description,
    required this.category,
    required this.tags,
    required this.isActive,
    required this.components,
  });

  final String id;
  final String slug;
  final String name;
  final String image;
  final String description;
  final String category;
  final List<String> tags;
  final bool isActive;
  final List<ProductComponentItem> components;

  int get componentCount => components.length;

  double get totalPrice {
    return components.fold<double>(0, (sum, item) => sum + item.price);
  }
}

class ProductComponentItem {
  const ProductComponentItem({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
  });

  final String id;
  final String name;
  final String description;
  final String image;
  final double price;
}