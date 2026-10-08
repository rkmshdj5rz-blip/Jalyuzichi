import 'orders.dart';

/// Namuna buyurtmalarning mijoz ismi shu bilan boshlanadi.
const samplePrefix = 'Namuna:';

/// Panelni sinab ko'rish uchun namuna buyurtmalar (haqiqiy mijozlar emas).
List<Order> sampleOrders(DateTime now, int firstNumber) {
  final today = dateOnly(now);
  DateTime day(int offset) => today.add(Duration(days: offset));
  OrderItem item(String type, String model, double price, List<List<num>> s) =>
      OrderItem(
        type: type,
        model: model,
        pricePerM2: price,
        sizes: [
          for (final x in s)
            OrderSize(
                width: x[0].toDouble(),
                height: x[1].toDouble(),
                count: x.length > 2 ? x[2].toInt() : 1),
        ],
      );
  Payment pay(double amount, int offset) =>
      Payment(amount: amount, date: day(offset));

  var n = firstNumber;
  return [
    Order(
      number: n++,
      branch: branches[0],
      customerType: CustomerType.client,
      customerName: 'Namuna: Aziz',
      customerPhone: '+998 90 111 22 33',
      createdAt: day(-9),
      installDate: day(-2),
      items: [item(productTypes[4], 'LIZBON-06', 320000, [[120, 150, 2], [80, 140]])],
      payments: [pay(300000, -9)],
    ),
    Order(
      number: n++,
      branch: branches[1],
      customerType: CustomerType.client,
      customerName: 'Namuna: Dilnoza',
      customerPhone: '+998 93 444 55 66',
      createdAt: day(-3),
      installDate: day(0),
      items: [item(productTypes[0], 'VR-12', 180000, [[200, 250], [150, 250]])],
      payments: [pay(400000, -3)],
    ),
    Order(
      number: n++,
      branch: branches[0],
      customerType: CustomerType.client,
      customerName: 'Namuna: Botir',
      customerPhone: '+998 94 777 88 99',
      createdAt: day(-1),
      installDate: day(1),
      items: [item(productTypes[3], 'ZEBRA-03', 260000, [[110, 160, 3]])],
    ),
    Order(
      number: n++,
      branch: branches[2],
      customerType: CustomerType.office,
      createdAt: day(-12),
      installDate: day(-6),
      installedAt: day(-6),
      items: [item(productTypes[2], 'ROL-21', 150000, [[90, 180, 4]])],
      payments: [pay(500000, -12)],
    ),
    Order(
      number: n++,
      branch: branches[1],
      customerType: CustomerType.client,
      customerName: 'Namuna: Kamola',
      customerPhone: '+998 97 123 45 67',
      createdAt: day(-20),
      installDate: day(-15),
      installedAt: day(-15),
      items: [item(productTypes[1], 'AL-25', 210000, [[140, 130, 2]])],
      payments: [pay(400000, -20), pay(364400, -15)],
    ),
    Order(
      number: n++,
      branch: branches[0],
      customerType: CustomerType.client,
      customerName: 'Namuna: Sardor',
      customerPhone: '+998 99 222 33 44',
      createdAt: day(0),
      items: [item(productTypes[5], 'RIM-08', 350000, [[160, 200]])],
    ),
  ];
}
