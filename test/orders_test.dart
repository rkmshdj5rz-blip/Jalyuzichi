import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalyuzichi/app_state.dart';
import 'package:jalyuzichi/data/orders.dart';
import 'package:jalyuzichi/main.dart';
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

  testWidgets("buyurtma kiritiladi va ro'yxatda ko'rinadi", (tester) async {
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

    await tester.tap(find.text('Buyurtmalar'));
    await tester.pumpAndSettle();
    expect(find.text("Hali buyurtma yo'q"), findsOneWidget);

    await tester.tap(find.text('Buyurtma'));
    await tester.pumpAndSettle();
    expect(find.text('№ 1001'), findsOneWidget);
    expect(find.text('Buyurtmachini tanlang'), findsOneWidget);

    await tester.tap(find.text('Mijoz'));
    await tester.pump();
    await tester.tap(find.text('Jalyuzi turi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rulonli parda').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'eni'), '120');
    await tester.enterText(find.widgetWithText(TextFormField, "bo'yi"), '150');
    await tester.pump();
    expect(find.text("1 o'lcham · 1,8 m²"), findsWidgets);

    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Ism familiya'), 'Aziz');
    await tester.enterText(
        find.widgetWithText(TextField, '+998 90 123 45 67'), '+998901112233');
    await tester.pump();
    await tester.tap(find.text('Buyurtmani saqlash'));
    await tester.pumpAndSettle();

    expect(find.text('№ 1001'), findsOneWidget);
    expect(find.text('Aziz'), findsOneWidget);
    expect(state.orders.single.area, closeTo(1.8, 1e-9));
    expect(state.nextOrderNumber, 1002);
  });
}
