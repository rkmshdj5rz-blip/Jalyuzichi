import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalyuzichi/app_state.dart';
import 'package:jalyuzichi/data/orders.dart';
import 'package:jalyuzichi/data/products.dart';
import 'package:jalyuzichi/screens/new_order_screen.dart';
import 'package:jalyuzichi/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets("lenta kodi qidirib tanlanadi, o'lcham sozlamalari qo'yiladi",
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    for (final (id, code, price) in [
      ('k1', 'M1607B', 110000.0),
      ('k2', '7002-3', 125000.0),
      ('k3', 'BN-3', 98000.0),
    ]) {
      await state.saveProduct(
          Product(id: id, type: 'Kombo', collection: code, price: price));
    }
    await tester.pumpWidget(AppScope(
      state: state,
      child: MaterialApp(
          theme: buildTheme(Brightness.light), home: const NewOrderScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jalyuzi turi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kombo').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lenta kodi'));
    await tester.pumpAndSettle();
    expect(find.text('3 ta kod'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Kodni yozing: L-101, 7002...'), '7002');
    await tester.pumpAndSettle();
    expect(find.text('1 ta kod'), findsOneWidget);
    expect(find.text('M1607B'), findsNothing);
    await tester.tap(find.text('7002-3'));
    await tester.pumpAndSettle();
    expect(find.text('7002-3'), findsOneWidget);
    expect(find.text('125 000'), findsOneWidget);

    expect(find.text('Zanjir · Chap · Karnizsiz'), findsOneWidget);
    await tester.tap(find.byTooltip('Sozlamalar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ctl-motor')));
    await tester.tap(find.byKey(const ValueKey('side-right')));
    await tester.tap(find.byKey(const ValueKey('karniz-field')));
    await tester.pumpAndSettle();
    expect(find.text('Premium biryuzoviy'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('karniz-Oq')));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('Tayyor'));
    await tester.pumpAndSettle();
    expect(find.text("Motor · O'ng · Karniz: Oq"), findsOneWidget);

    // Yangi o'lcham oldingi sozlamalarni oladi.
    await tester.tap(find.text("O'lcham"));
    await tester.pumpAndSettle();
    expect(find.text("Motor · O'ng · Karniz: Oq"), findsNWidgets(2));

    final s = OrderSize.fromJson(
        (OrderSize(width: 1, height: 1)..control = Control.motor).toJson());
    expect(s.control, Control.motor);
  });
}
