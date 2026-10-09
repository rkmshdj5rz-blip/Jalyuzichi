import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalyuzichi/app_state.dart';
import 'package:jalyuzichi/screens/prices_screen.dart';
import 'package:jalyuzichi/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets("mahsulot tur, lenta kodi va narx bilan qo'shiladi",
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    await tester.pumpWidget(AppScope(
      state: state,
      child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const Scaffold(body: PricesScreen())),
    ));
    final before = state.products.length;

    expect(find.text('Jalyuzi turini yozing'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Jalyuzi turi'), 'Kombo');
    await tester.enterText(
        find.widgetWithText(TextField, 'Lenta kodi'), 'Collection-1');
    await tester.enterText(
        find.widgetWithText(TextField, '1 m² narxi'), '110000');
    await tester.pump();
    await tester.tap(find.text("Qo'shish"));
    await tester.pumpAndSettle();

    final p = state.findProduct('kombo', 'collection-1')!;
    expect(p.type, 'Kombo');
    expect(p.price, 110000);
    expect(state.products.length, before + 1);
    // Tur saqlanib qoladi, keyingi lenta darhol yoziladi.
    expect(find.text('Kombo'), findsWidgets);

    await tester.enterText(
        find.widgetWithText(TextField, 'Lenta kodi'), 'Collection-2');
    await tester.enterText(
        find.widgetWithText(TextField, '1 m² narxi'), '125000');
    await tester.pump();
    await tester.tap(find.text("Qo'shish"));
    await tester.pumpAndSettle();
    expect(state.products.where((p) => p.type == 'Kombo').length, 2);

    // Bor mahsulotni qayta qo'shsa, narxi yangilanadi.
    await tester.enterText(
        find.widgetWithText(TextField, 'Lenta kodi'), 'collection-1');
    await tester.enterText(
        find.widgetWithText(TextField, '1 m² narxi'), '115000');
    await tester.pump();
    await tester.tap(find.text("Qo'shish"));
    await tester.pumpAndSettle();
    expect(state.findProduct('Kombo', 'Collection-1')!.price, 115000);
    expect(state.products.where((p) => p.type == 'Kombo').length, 2);
  });
}
