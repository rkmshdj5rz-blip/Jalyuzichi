import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalyuzichi/app_state.dart';
import 'package:jalyuzichi/main.dart';
import 'package:jalyuzichi/screens/home_screen.dart';
import 'package:jalyuzichi/screens/otp_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('kirish ketma-ketligi bosh sahifagacha yetadi', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    await tester.pumpWidget(
      AppScope(state: state, child: const JalyuzichiApp(startLoggedIn: false)),
    );

    expect(find.text('Davlatni tanlang'), findsOneWidget);
    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle();

    expect(find.text('Xush kelibsiz'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '901234567');
    await tester.pump();
    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle();

    expect(find.text('Tasdiqlash'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '11111');
    await tester.pump();
    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining("Kod noto'g'ri"), findsOneWidget);

    await tester.enterText(find.byType(TextField), demoSmsCode);
    await tester.pump();
    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text("Ismingiz"), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Murod');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, "Ro'yxatdan o'tish"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sinxronlash'), findsOneWidget);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Manzil kiritish'), findsOneWidget);
    expect(state.isLoggedIn, isTrue);
    expect(state.phone, '+998901234567');
    expect(state.name, 'Murod');
  });
}
