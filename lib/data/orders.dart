// Buyurtma va uning ichidagi mahsulotlar.

/// Birinchi ishga tushganda yaratiladigan filiallar.
const defaultBranchNames = [
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

/// Boshlang'ich narxlar (1 m² uchun, so'm). "Narxlar" bo'limida o'zgartiriladi.
const defaultPrices = {
  'Vertikal jalyuzi': 120000.0,
  'Gorizontal jalyuzi': 110000.0,
  'Rulonli parda': 150000.0,
  'Kun-tun (zebra) parda': 190000.0,
  'Plisse parda': 250000.0,
  'Rim pardasi': 220000.0,
};

enum CustomerType { office, client }

extension CustomerTypeLabel on CustomerType {
  String get label =>
      this == CustomerType.office ? 'Ofis buyurtmasi' : 'Mijoz';
}

/// Bitta o'lcham: eni va bo'yi santimetrda, soni dona.
/// Boshqaruv turi.
enum Control {
  none("Bo'sh"),
  chain('Zanjir'),
  motor('Motor'),
  manual("Qo'l");

  const Control(this.label);
  final String label;
}

/// Boshqaruv qaysi tomonda.
enum Side {
  left('Chap'),
  right("O'ng"),
  both("Chap+O'ng");

  const Side(this.label);
  final String label;
}

/// Karniz variantlari (rangi bilan).
const karnizOptions = [
  'Karnizsiz',
  'Oq',
  'Kumush',
  'Jigarrang',
  'Qora',
  'Oltin',
];

class OrderSize {
  OrderSize({
    this.width = 0,
    this.height = 0,
    this.count = 1,
    this.control = Control.chain,
    this.side = Side.left,
    this.karniz = 'Karnizsiz',
  });

  double width;
  double height;
  int count;
  Control control;
  Side side;
  String karniz;

  bool get isValid => width > 0 && height > 0 && count > 0;

  /// Kvadrat metr (barcha donalar bilan).
  double get area => width * height / 10000 * count;

  /// Sozlamalar qisqacha: "Zanjir · Chap · Oq karniz".
  String get optionsLabel => [
        control.label,
        if (control != Control.none) side.label,
        karniz == 'Karnizsiz' ? 'Karnizsiz' : '$karniz karniz',
      ].join(' · ');

  void copyOptionsFrom(OrderSize o) {
    control = o.control;
    side = o.side;
    karniz = o.karniz;
  }

  Map<String, dynamic> toJson() => {
        'w': width,
        'h': height,
        'n': count,
        'ctl': control.name,
        'side': side.name,
        'karniz': karniz,
      };

  factory OrderSize.fromJson(Map<String, dynamic> j) => OrderSize(
        width: (j['w'] as num).toDouble(),
        height: (j['h'] as num).toDouble(),
        count: j['n'] as int,
        control: Control.values.asNameMap()[j['ctl']] ?? Control.chain,
        side: Side.values.asNameMap()[j['side']] ?? Side.left,
        karniz: j['karniz'] as String? ?? 'Karnizsiz',
      );
}

class OrderItem {
  OrderItem({
    this.type,
    List<OrderSize>? sizes,
    this.pricePerM2 = 0,
    this.model = '',
  }) : sizes = sizes ?? [OrderSize()];

  String? type;

  /// Mato yoki model kodi, masalan "LIZBON-06".
  String model;
  final List<OrderSize> sizes;

  /// 1 m² narxi, so'mda.
  double pricePerM2;

  double get sum => area * pricePerM2;

  Iterable<OrderSize> get validSizes => sizes.where((s) => s.isValid);
  double get area => validSizes.fold(0, (a, s) => a + s.area);
  int get sizeCount => validSizes.fold(0, (a, s) => a + s.count);
  bool get isValid => type != null && validSizes.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'type': type,
        'price': pricePerM2,
        'model': model,
        'sizes': [for (final s in validSizes) s.toJson()],
      };

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        type: j['type'] as String?,
        pricePerM2: (j['price'] as num?)?.toDouble() ?? 0,
        model: j['model'] as String? ?? '',
        sizes: [
          for (final s in j['sizes'] as List)
            OrderSize.fromJson(s as Map<String, dynamic>),
        ],
      );
}

/// To'lov usuli.
enum PayMethod {
  cash('Naqd', 'naqd'),
  card('Karta', 'karta'),
  dollar('Dollar', 'dollar');

  const PayMethod(this.label, this.lower);
  final String label;
  final String lower;
}

/// Kassaga tushgan to'lov. [amount] har doim so'mda; dollarda to'langanda
/// [usd] va [rate] ham saqlanadi.
class Payment {
  Payment({
    required this.amount,
    required this.date,
    this.method = PayMethod.cash,
    this.usd,
    this.rate,
  });

  final double amount;
  final DateTime date;
  final PayMethod method;
  final double? usd;
  final double? rate;

  /// "250 000 so'm" yoki "$20 (kurs 12 800)".
  String get display => method == PayMethod.dollar && usd != null
      ? '\$${formatNumber(usd!)} · kurs ${formatNumber(rate ?? 0)}'
      : formatMoney(amount);

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'date': date.toIso8601String(),
        'method': method.name,
        if (usd != null) 'usd': usd,
        if (rate != null) 'rate': rate,
      };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String),
        method: PayMethod.values.asNameMap()[j['method']] ?? PayMethod.cash,
        usd: (j['usd'] as num?)?.toDouble(),
        rate: (j['rate'] as num?)?.toDouble(),
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
    this.discount = 0,
    List<Payment>? payments,
    this.installedAt,
  }) : payments = payments ?? [];

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

  /// Chegirma, so'mda.
  final double discount;
  final List<Payment> payments;

  /// O'rnatilgan kun (o'rnatilmagan bo'lsa null).
  DateTime? installedAt;

  Order copyWith({DateTime? installDate, bool clearInstallDate = false}) =>
      Order(
        number: number,
        branch: branch,
        customerType: customerType,
        items: items,
        createdAt: createdAt,
        customerName: customerName,
        customerPhone: customerPhone,
        address: address,
        note: note,
        installDate:
            clearInstallDate ? null : (installDate ?? this.installDate),
        discount: discount,
        payments: payments,
        installedAt: installedAt,
      );

  bool get isInstalled => installedAt != null;
  bool get isPaid => total > 0 && remaining == 0;

  /// O'rnatish sanasi bugundan necha kun keyin (o'tgan bo'lsa manfiy).
  int? daysToInstall(DateTime now) => installDate == null
      ? null
      : dateOnly(installDate!).difference(dateOnly(now)).inDays;

  bool isOverdue(DateTime now) =>
      !isInstalled && (daysToInstall(now) ?? 0) < 0;
  double get total =>
      (items.fold<double>(0, (a, i) => a + i.sum) - discount).clamp(0, double.infinity);
  double get paid => payments.fold(0, (a, p) => a + p.amount);
  double get remaining => (total - paid).clamp(0, double.infinity);

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
        'discount': discount,
        'payments': [for (final p in payments) p.toJson()],
        'installedAt': installedAt?.toIso8601String(),
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
        discount: (j['discount'] as num?)?.toDouble() ?? 0,
        payments: [
          for (final p in (j['payments'] as List?) ?? const [])
            Payment.fromJson(p as Map<String, dynamic>),
        ],
        installedAt: j['installedAt'] == null
            ? null
            : DateTime.parse(j['installedAt'] as String),
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

/// "25 860 254 so'm".
String formatMoney(double v) => "${formatNumber(v)} so'm";

/// "25 860 254" (so'zsiz).
String formatNumber(double v) {
  final digits = v.round().abs().toString();
  final buf = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// "1 250 000" kabi matndan summani oladi.
double parseMoney(String s) =>
    double.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Panel uchun davr.
enum Period { today, week, month, all }

extension PeriodLabel on Period {
  String get label => switch (this) {
        Period.today => 'Bugun',
        Period.week => '7 kun',
        Period.month => 'Shu oy',
        Period.all => 'Hammasi',
      };

  bool contains(DateTime d, DateTime now) {
    final today = dateOnly(now);
    return switch (this) {
      Period.today => !d.isBefore(today),
      Period.week => !d.isBefore(today.subtract(const Duration(days: 6))),
      Period.month => d.year == now.year && d.month == now.month,
      Period.all => true,
    };
  }
}

/// Buyurtmalar paneli ko'rsatkichlari.
class OrderStats {
  OrderStats(List<Order> orders, DateTime now) {
    final today = dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    for (final o in orders) {
      count++;
      total += o.total;
      paid += o.paid;
      if (o.isInstalled) {
        if (o.remaining > 0) {
          debt += o.remaining;
          debtCount++;
        }
        continue;
      }
      remaining += o.remaining;
      remainingCount++;
      final d = o.installDate == null ? null : dateOnly(o.installDate!);
      if (d == null) {
        noDate++;
      } else if (d.isBefore(today)) {
        overdue++;
        final late = today.difference(d).inDays;
        if (late > maxLateDays) maxLateDays = late;
      } else if (d == today) {
        installToday++;
      } else if (d == tomorrow) {
        installTomorrow++;
      }
    }
  }

  int count = 0;
  double total = 0;
  double paid = 0;
  double debt = 0;
  int debtCount = 0;
  double remaining = 0;
  int remainingCount = 0;
  int overdue = 0;
  int maxLateDays = 0;
  int installToday = 0;
  int installTomorrow = 0;
  int noDate = 0;

  int get paidPercent => total == 0 ? 0 : (paid / total * 100).round();
}

/// Buyurtmalar ro'yxatidagi holat filtri.
enum OrderFilter {
  all('Hammasi'),
  overdue("Muddati o'tgan"),
  today('Bugun'),
  tomorrow('Ertaga'),
  waiting('Montaj kutilmoqda'),
  installed("O'rnatilgan"),
  debtor("Qarzdor (o'rnatilgan)"),
  remaining("Qoldiq (o'rnatilmagan)"),
  paid("To'langan"),
  noDate('Sanasiz');

  const OrderFilter(this.label);
  final String label;

  bool test(Order o, DateTime now) => switch (this) {
        OrderFilter.all => true,
        OrderFilter.overdue => o.isOverdue(now),
        OrderFilter.today => !o.isInstalled && o.daysToInstall(now) == 0,
        OrderFilter.tomorrow => !o.isInstalled && o.daysToInstall(now) == 1,
        OrderFilter.waiting => !o.isInstalled,
        OrderFilter.installed => o.isInstalled,
        OrderFilter.debtor => o.isInstalled && o.remaining > 0,
        OrderFilter.remaining => !o.isInstalled && o.remaining > 0,
        OrderFilter.paid => o.isPaid,
        OrderFilter.noDate => !o.isInstalled && o.installDate == null,
      };
}

enum OrderSort {
  auto('Avto tartib'),
  newest('Avval yangilari'),
  install('Montaj sanasi bo\'yicha');

  const OrderSort(this.label);
  final String label;
}

/// Avto tartib: muddati o'tganlar, keyin yaqin montajlar, sanasizlar,
/// oxirida o'rnatilganlar.
List<Order> sortOrders(List<Order> orders, OrderSort sort, DateTime now) {
  final list = [...orders];
  int byNumberDesc(Order a, Order b) => b.number.compareTo(a.number);
  switch (sort) {
    case OrderSort.newest:
      list.sort(byNumberDesc);
    case OrderSort.install:
    case OrderSort.auto:
      int rank(Order o) {
        if (o.isInstalled) return 3;
        if (o.installDate == null) return sort == OrderSort.auto ? 2 : 1;
        return sort == OrderSort.auto ? (o.isOverdue(now) ? 0 : 1) : 0;
      }
      list.sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        final da = a.installDate, db = b.installDate;
        if (da != null && db != null && !a.isInstalled) {
          final c = da.compareTo(db);
          if (c != 0) return c;
        }
        return byNumberDesc(a, b);
      });
  }
  return list;
}

const _months = [
  'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
  'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr',
];

/// "8 oktabr".
String formatDay(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// "+998901234567" → "+998 90 123 45 67".
String formatPhone(String p) {
  final m = RegExp(r'^\+998(\d{2})(\d{3})(\d{2})(\d{2})$').firstMatch(p);
  return m == null ? p : '+998 ${m[1]} ${m[2]} ${m[3]} ${m[4]}';
}
