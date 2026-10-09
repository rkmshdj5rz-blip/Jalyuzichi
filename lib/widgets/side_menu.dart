import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/orders.dart';
import '../screens/branches_screen.dart';
import '../screens/cabinet_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/profile_screen.dart';
import '../theme.dart';
import 'app_logo.dart';

/// Yon menyu. [onTab] pastki menyu bo'limini ochadi.
class SideMenu extends StatelessWidget {
  const SideMenu({super.key, required this.onTab, required this.onOrders});

  final ValueChanged<int> onTab;
  final void Function({OrdersSection section}) onOrders;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final dark = state.themeMode == ThemeMode.dark;

    Widget item(IconData icon, String title, VoidCallback onTap,
        {bool selected = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: ListTile(
          selected: selected,
          selectedTileColor: AppColors.brand,
          selectedColor: AppColors.onBrand,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
        ),
      );
    }

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const AppLogo(size: 48, showName: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.name.isEmpty ? 'Mehmon' : state.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(formatPhone(state.phone),
                            style: const TextStyle(color: AppColors.lightMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 20, endIndent: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  item(Icons.home_rounded, 'Bosh sahifa', () {},
                      selected: true),
                  item(Icons.receipt_long_outlined, 'Buyurtmalar',
                      () => onOrders()),
                  item(Icons.account_balance_wallet_outlined, 'Kassa jurnali',
                      () => onOrders(section: OrdersSection.cash)),
                  item(Icons.local_shipping_outlined, 'Tsexdan yuklar',
                      () => onOrders(section: OrdersSection.workshop)),
                  item(Icons.store_outlined, 'Filiallar', () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const BranchesScreen()));
                  }),
                  item(Icons.sell_outlined, 'Narxlar', () => onTab(2)),
                  item(Icons.person_outline_rounded, 'Kabinet', () => onTab(3)),
                  item(Icons.edit_outlined, 'Profilni tahrirlash', () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ProfileScreen()));
                  }),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: SwitchListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Tungi rejim',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      value: dark,
                      onChanged: state.setDark,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Chiqish',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () => confirmLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
