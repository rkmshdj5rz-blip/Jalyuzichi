// Buyurtma va uning ichidagi mahsulotlar.

const branches = [
  '№1 Toshkent filiali',
  '№2 Angren filiali',
  '№3 Chirchiq filiali',
];

const productTypes = [
  'Vertikal jalyuzi',
  'Gorizontal jalyuzi',
  'Rulonli parda',
  'Kun-tun (zebra) parda',
  'Plisse parda',
  'Rim pardasi',
];

enum CustomerType { office, client }

extension CustomerTypeLabel on CustomerType {
  String get label =>
      this == CustomerType.office ? 'Ofis buyurtmasi' : 'Mijoz';
}

/// Bitta o'lcham: eni va bo'yi santimetrda, soni dona.
class OrderSize {
  OrderSize({this.width = 0, this.height = 0, this.count = 1});

  double width;
  double height;
  int count;

  bool get isValid => width > 0 && height > 0 && count > 0;

  /// Kvadrat metr (barcha donalar bilan).
  double get area => width * height / 10000 * count;

  Map<String, dynamic> toJson() => {'w': width, 'h': height, 'n': count};

  factory OrderSize.fromJson(Map<String, dynamic> j) => OrderSize(
        width: (j['w'] as num).toDouble(),
        height: (j['h'] as num).toDouble(),
        count: j['n'] as int,
      );
}

class OrderItem {
  OrderItem({this.type, List<OrderSize>? sizes})
      : sizes = sizes ?? [OrderSize()];

  String? type;
  final List<OrderSize> sizes;

  Iterable<OrderSize> get validSizes => sizes.where((s) => s.isValid);
  double get area => validSizes.fold(0, (a, s) => a + s.area);
  int get sizeCount => validSizes.fold(0, (a, s) => a + s.count);
  bool get isValid => type != null && validSizes.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'type': type,
        'sizes': [for (final s in validSizes) s.toJson()],
      };

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        type: j['type'] as String?,
        sizes: [
          for (final s in j['sizes'] as List)
            OrderSize.fromJson(s as Map<String, dynamic>),
        ],
      );
}

class Order {
  Order({
    required this.number,
    required this.branch,
    required this.customerType,
    required this.items,
    required this.createdAt,
    this.customerName = '',
    this.customerPhone = '',
    this.address = '',
    this.note = '',
    this.installDate,
  });

  final int number;
  final String branch;
  final CustomerType customerType;
  final List<OrderItem> items;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;
  final String address;
  final String note;
  final DateTime? installDate;

  double get area => items.fold(0, (a, i) => a + i.area);
  int get sizeCount => items.fold(0, (a, i) => a + i.sizeCount);

  String get customerLabel => customerType == CustomerType.office
      ? 'Ofis buyurtmasi'
      : (customerName.isEmpty ? 'Mijoz' : customerName);

  Map<String, dynamic> toJson() => {
        'number': number,
        'branch': branch,
        'customerType': customerType.name,
        'items': [for (final i in items) i.toJson()],
        'createdAt': createdAt.toIso8601String(),
        'customerName': customerName,
        'customerPhone': customerPhone,
        'address': address,
        'note': note,
        'installDate': installDate?.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        number: j['number'] as int,
        branch: j['branch'] as String,
        customerType: CustomerType.values.byName(j['customerType'] as String),
        items: [
          for (final i in j['items'] as List)
            OrderItem.fromJson(i as Map<String, dynamic>),
        ],
        createdAt: DateTime.parse(j['createdAt'] as String),
        customerName: j['customerName'] as String? ?? '',
        customerPhone: j['customerPhone'] as String? ?? '',
        address: j['address'] as String? ?? '',
        note: j['note'] as String? ?? '',
        installDate: j['installDate'] == null
            ? null
            : DateTime.parse(j['installDate'] as String),
      );
}

/// "120x150", "120 x 150 2", "80*200=3" kabi qatorlardan o'lchamlarni oladi.
List<OrderSize> parseSizes(String text) {
  final re = RegExp(
      r'(\d+(?:[.,]\d+)?)[ \t]*[x×х*][ \t]*(\d+(?:[.,]\d+)?)(?:[ \t]*[=\- \t][ \t]*(\d+))?',
      caseSensitive: false);
  double num(String s) => double.parse(s.replaceAll(',', '.'));
  return [
    for (final m in re.allMatches(text))
      OrderSize(
        width: num(m[1]!),
        height: num(m[2]!),
        count: m[3] == null ? 1 : int.parse(m[3]!),
      ),
  ];
}

/// "1,25" ko'rinishida (o'zbekcha kasr belgisi bilan).
String formatArea(double v) => v
    .toStringAsFixed(2)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
