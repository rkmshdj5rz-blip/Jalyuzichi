import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalyuzichi/app_state.dart';
import 'package:jalyuzichi/data/branches.dart';
import 'package:jalyuzichi/data/orders.dart';
import 'package:jalyuzichi/data/sample_orders.dart';
import 'package:jalyuzichi/screens/branches_screen.dart';
import 'package:jalyuzichi/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test("filial nomi o'zgarsa buyurtmalarda ham o'zgaradi", () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    expect(state.branches.length, defaultBranchNames.length);
    await state.addOrders(sampleOrders(DateTime.now(), 1001));
    final first = state.branches.first;
    final before = state.ordersIn(first);
    expect(before, greaterThan(0));

    await state.saveBranch(first..name = 'Markaziy filial');
    expect(state.branches.first.name, 'Markaziy filial');
    expect(state.orders.where((o) => o.branch == 'Markaziy filial').length,
        before);

    await state.saveBranch(Branch(id: 'x', name: "Yangi do'kon",
        kind: BranchKind.shop));
    expect(state.branches.length, 4);
    await state.setMainBranch('x');
    expect(state.mainBranch!.name, "Yangi do'kon");

    await state.deleteBranch('x');
    expect(state.branches.length, 3);
    expect(state.mainBranch!.id, state.branches.first.id);
    // Buyurtmalar o'chmaydi.
    expect(state.orders.length, greaterThan(0));

    await state.saveBranch(state.branches.first..active = false);
    expect(state.activeBranches.length, 2);
  });

  testWidgets("yangi filial qo'shiladi", (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    await tester.pumpWidget(AppScope(
      state: state,
      child: MaterialApp(
          theme: buildTheme(Brightness.light), home: const BranchesScreen()),
    ));
    expect(find.text('3 ta · 3 ta faol'), findsOneWidget);
    await tester.tap(find.text("Filial qo'shish"));
    await tester.pumpAndSettle();
    expect(find.text('Nomini kiriting'), findsOneWidget);
    await tester.tap(find.text("Do'kon"));
    await tester.enterText(
        find.widgetWithText(TextField, 'Nomi'), '№4 Olmaliq filiali');
    await tester.pump();
    await tester.tap(find.text("Qo'shish"));
    await tester.pumpAndSettle();
    expect(state.branches.last.name, '№4 Olmaliq filiali');
    expect(state.branches.last.kind, BranchKind.shop);
    expect(find.text('4 ta · 4 ta faol'), findsOneWidget);
  });
}
