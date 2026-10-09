// Mahsulotlar katalogi: jalyuzi turi, collection va 1 m² narxi.

import 'orders.dart';

class Product {
  Product({
    required this.id,
    required this.type,
    required this.collection,
    required this.price,
  });

  final String id;

  /// Jalyuzi turi, masalan "Kombo".
  String type;

  /// Lenta kodi, masalan "L-101".
  String collection;

  /// 1 m² narxi, so'mda.
  double price;

  String get label => collection.isEmpty ? type : '$type · $collection';

  Map<String, dynamic> toJson() =>
      {'id': id, 'type': type, 'collection': collection, 'price': price};

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        type: j['type'] as String,
        collection: j['collection'] as String? ?? '',
        price: (j['price'] as num).toDouble(),
      );
}

/// Birinchi ishga tushganda katalogda turadigan namunaviy mahsulotlar.
List<Product> defaultProducts() => [
      for (var i = 0; i < productTypes.length; i++)
        Product(
          id: 'p${i + 1}',
          type: productTypes[i],
          collection: 'L-${101 + i}',
          price: defaultPrices[productTypes[i]] ?? 0,
        ),
    ];

/// Turlar ro'yxati (katalogdagi tartibda, takrorlanmasdan).
List<String> typesOf(List<Product> products) =>
    {for (final p in products) p.type}.toList();
