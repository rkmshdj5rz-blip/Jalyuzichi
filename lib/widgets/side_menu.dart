import 'package:flutter/material.dart';

import '../app_state.dart';
import '../screens/country_screen.dart';
import '../screens/profile_screen.dart';
import '../theme.dart';
import 'app_logo.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  void _soon(BuildContext context, String what) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$what bo'limi tez orada qo'shiladi")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final dark = state.themeMode == ThemeMode.dark;

    Widget item(IconData icon, String title, {VoidCallback? onTap, bool selected = false}) {
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
          onTap: onTap ?? () => _soon(context, title),
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
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(state.phone,
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
                  item(Icons.home_rounded, 'Bosh sahifa',
                      selected: true, onTap: () => Navigator.of(context).pop()),
                  item(Icons.person_outline_rounded, 'Profilni tahrirlash',
                      onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ProfileScreen()));
                  }),
                  item(Icons.language_rounded, 'Til'),
                  item(Icons.account_balance_wallet_outlined, "To'lovlar"),
                  item(Icons.local_offer_outlined, 'Promokod'),
                  item(Icons.support_agent_rounded, "Bog'lanish"),
                  item(Icons.tune_rounded, 'Sozlamalar'),
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
                  item(Icons.report_gmailerrorred_rounded,
                      'Muammo haqida xabar'),
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
                onTap: () async {
                  final nav = Navigator.of(context);
                  await state.logout();
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const CountryScreen()),
                    (_) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
