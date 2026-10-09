import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalyuzichi/app_state.dart';
import 'package:jalyuzichi/data/orders.dart';
import 'package:jalyuzichi/data/sample_orders.dart';
import 'package:jalyuzichi/main.dart';
import 'package:jalyuzichi/widgets/money_field.dart';
import 'package:jalyuzichi/widgets/payment_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test("matndan o'lchamlarni ajratadi", () {
    final s = parseSizes('120x150\n80 х 200 2\n55,5*100=2\nsalom');
    expect(s.length, 3);
    expect(s[0].width, 120);
    expect(s[1].count, 2);
    expect(s[2].width, 55.5);
    expect(s[2].count, 2);
    expect(formatArea(s.fold(0.0, (a, x) => a + x.area)), '6,11');
  });

  test('summa va telefon formatlari', () {
    expect(formatMoney(25860254), "25 860 254 so'm");
    expect(parseMoney('1 250 000'), 1250000);
    expect(formatPhone('+998901234567'), '+998 90 123 45 67');
    const f = MoneyInputFormatter();
    expect(
        f.formatEditUpdate(TextEditingValue.empty,
                const TextEditingValue(text: '1250000'))
            .text,
        '1 250 000');
  });

  test("panel ko'rsatkichlari va filtrlar namuna buyurtmalarda to'g'ri", () {
    final now = DateTime(2026, 10, 8, 12);
    final orders = sampleOrders(now, 1001);
    final stats = OrderStats(orders, now);
    expect(stats.count, orders.length);
    expect(stats.total, closeTo(orders.fold(0.0, (a, o) => a + o.total), 1));
    expect(stats.paid + stats.debt + stats.remaining, closeTo(stats.total, 1));
    for (final f in OrderFilter.values) {
      final n = orders.where((o) => f.test(o, now)).length;
      switch (f) {
        case OrderFilter.all:
          expect(n, orders.length);
        case OrderFilter.overdue:
          expect(n, stats.overdue);
        case OrderFilter.today:
          expect(n, stats.installToday);
        case OrderFilter.tomorrow:
          expect(n, stats.installTomorrow);
        case OrderFilter.noDate:
          expect(n, stats.noDate);
        case OrderFilter.debtor:
          expect(n, stats.debtCount);
        case OrderFilter.remaining:
          expect(n, lessThanOrEqualTo(stats.remainingCount));
        default:
          break;
      }
    }
    // Avto tartibda muddati o'tganlar birinchi, o'rnatilganlar oxirida.
    final sorted = sortOrders(orders, OrderSort.auto, now);
    if (stats.overdue > 0) expect(sorted.first.isOverdue(now), isTrue);
    expect(sorted.last.isInstalled, isTrue);
  });

  test("dollarda to'lov so'mga kurs bo'yicha o'tadi", () {
    final d = PaymentDraft(rate: 12800)
      ..method = PayMethod.dollar
      ..usd = 20;
    expect(d.amount, 256000);
    final p = Payment.fromJson(d.toPayment(DateTime(2026, 10, 9)).toJson());
    expect(p.method, PayMethod.dollar);
    expect(p.usd, 20);
    expect(p.amount, 256000);
  });

  test("to'lov qo'shilgach qoldiq kamayadi", () {
    final o = Order(
      number: 1,
      branch: defaultBranchNames.first,
      customerType: CustomerType.client,
      createdAt: DateTime(2026, 10, 1),
      discount: 20000,
      items: [
        OrderItem(
            type: productTypes.first,
            pricePerM2: 100000,
            sizes: [OrderSize(width: 100, height: 200)]),
      ],
    );
    expect(o.total, 180000);
    o.payments.add(Payment(amount: 80000, date: DateTime(2026, 10, 2)));
    expect(o.remaining, 100000);
    expect(o.isPaid, isFalse);
    o.payments.add(Payment(amount: 100000, date: DateTime(2026, 10, 3)));
    expect(o.isPaid, isTrue);
    final back = Order.fromJson(o.toJson());
    expect(back.total, 180000);
    expect(back.paid, 180000);
  });

  testWidgets("buyurtma narx va zaklad bilan kiritiladi", (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'loggedIn': true,
      'name': 'Murod',
      'phone': '+998901234567',
      'region': 'Toshkent shahri',
      'district': 'Chilonzor',
    });
    final state = await AppState.load();
    await tester.pumpWidget(
        AppScope(state: state, child: const JalyuzichiApp(startLoggedIn: true)));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Buyurtmalar')));
    await tester.pumpAndSettle();
    expect(find.text("Hali buyurtma yo'q"), findsOneWidget);

    await tester.tap(find.text('Yangi buyurtma'));
    await tester.pumpAndSettle();
    expect(find.text('№ 1001'), findsOneWidget);
    expect(find.text('Buyurtmachini tanlang'), findsOneWidget);

    await tester.tap(find.text('Mijoz'));
    await tester.pump();
    await tester.tap(find.text('Jalyuzi turi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rulonli parda').last);
    await tester.pumpAndSettle();
    // Narx "Narxlar"dan o'zi qo'yiladi.
    expect(find.text('150 000'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'eni'), '120');
    await tester.enterText(find.widgetWithText(TextFormField, "bo'yi"), '150');
    await tester.pump();
    expect(find.text('1 dona · 1,8 m²'), findsWidgets);
    expect(find.text("270 000 so'm"), findsWidgets);

    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Ism familiya'), 'Aziz');
    await tester.enterText(
        find.widgetWithText(TextField, '+998 90 123 45 67'), '+998901112233');
    // Foizda: 10% → 27 000 so'm chegirma.
    await tester.enterText(find.widgetWithText(TextField, 'Chegirma'), '10');
    await tester.pump();
    expect(find.text("243 000 so'm"), findsWidgets);
    // So'mda.
    await tester.ensureVisible(find.byKey(const ValueKey('discount-sum')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('discount-sum')));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Chegirma'), '20000');
    await tester.enterText(
        find.widgetWithText(TextField, 'Avans'), '100000');
    await tester.pump();
    expect(find.text("250 000 so'm"), findsWidgets);
    await tester.tap(find.text('Buyurtmani saqlash'));
    await tester.pumpAndSettle();

    // Avans uchun chek chiqadi.
    expect(find.text('AVANS CHEKI'), findsOneWidget);
    expect(find.text('Telegramga yuborish'), findsOneWidget);
    await tester.tap(find.byTooltip('Yopish'));
    await tester.pumpAndSettle();

    final o = state.orders.single;
    expect(o.area, closeTo(1.8, 1e-9));
    expect(o.items.single.model, 'Standart');
    expect(o.total, 250000);
    expect(o.paid, 100000);
    expect(state.nextOrderNumber, 1002);
    await tester.scrollUntilVisible(find.text('Aziz'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('№ 1001'), findsOneWidget);

    // Kartadan to'lov qabul qilish.
    await tester.ensureVisible(find.text("To'lov"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("To'lov"));
    await tester.pumpAndSettle();
    expect(find.text('150 000'), findsOneWidget);
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();
    expect(state.orders.single.isPaid, isTrue);
  });
}
