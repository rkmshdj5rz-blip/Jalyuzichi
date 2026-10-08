import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../data/orders.dart';
import '../theme.dart';
import '../widgets/address_sheet.dart';
import 'country_screen.dart';
import 'profile_screen.dart';

const supportPhone = '+998 71 200 00 00';

/// Kabinet: profil, oylik natija va sozlamalar.
class CabinetScreen extends StatelessWidget {
  const CabinetScreen({super.key, required this.onOpenOrders});

  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = DateTime.now();
    final month = [
      for (final o in state.orders)
        if (Period.month.contains(o.createdAt, now)) o,
    ];
    final income = state.orders
        .expand((o) => o.payments)
        .where((p) => Period.month.contains(p.date, now))
        .fold<double>(0, (a, p) => a + p.amount);
    final debt = OrderStats(state.orders, now).debt;
    final name = state.name.isEmpty ? 'Mehmon' : state.name;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('Kabinet',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 16),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.brand,
                      child: Text(name.characters.first.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onBrand)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(formatPhone(state.phone),
                              style:
                                  const TextStyle(color: AppColors.lightMuted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined,
                        size: 20, color: AppColors.lightMuted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _Caption('Shu oy'),
          Row(
            children: [
              _Metric(
                  label: 'Buyurtma',
                  value: '${month.length} ta',
                  onTap: onOpenOrders),
              const SizedBox(width: 10),
              _Metric(
                  label: 'Kassaga tushdi',
                  value: formatMoney(income),
                  onTap: onOpenOrders),
              const SizedBox(width: 10),
              _Metric(
                  label: 'Qarzlar',
                  value: formatMoney(debt),
                  color: debt > 0 ? const Color(0xFFE5484D) : null,
                  onTap: onOpenOrders),
            ],
          ),
          const SizedBox(height: 20),
          const _Caption('Sozlamalar'),
          Card(
            child: Column(
              children: [
                _Item(
                  icon: Icons.location_on_outlined,
                  title: 'Manzil',
                  value: state.hasAddress ? state.district : 'Kiritilmagan',
                  onTap: () => showAddressSheet(context),
                ),
                _divider,
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Tungi rejim',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  value: state.themeMode == ThemeMode.dark,
                  onChanged: state.setDark,
                ),
                _divider,
                _Item(
                  icon: Icons.language_rounded,
                  title: 'Til',
                  value: "O'zbekcha",
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Rus tili keyingi yangilanishda qo'shiladi")),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _Caption('Yordam'),
          Card(
            child: Column(
              children: [
                _Item(
                  icon: Icons.headset_mic_outlined,
                  title: "Qo'llab-quvvatlash",
                  value: supportPhone,
                  onTap: () => launchUrl(
                      Uri(scheme: 'tel', path: supportPhone.replaceAll(' ', ''))),
                ),
                if (state.hasSamples) ...[
                  _divider,
                  _Item(
                    icon: Icons.auto_delete_outlined,
                    title: "Namuna buyurtmalarni o'chirish",
                    onTap: () async {
                      await state.removeSamples();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Namuna buyurtmalar o'chirildi")),
                        );
                      }
                    },
                  ),
                ],
                _divider,
                const _Item(
                  icon: Icons.info_outline_rounded,
                  title: 'Ilova haqida',
                  value: 'Jalyuzichi 1.0.0',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE5484D),
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: Color(0x55E5484D)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Hisobdan chiqish'),
          ),
        ],
      ),
    );
  }
}

/// Chiqishni so'rab, tasdiqlansa kirish ekraniga qaytaradi.
Future<void> confirmLogout(BuildContext context) => _logout(context);

Future<void> _logout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Hisobdan chiqasizmi?'),
      content: const Text(
          'Buyurtmalar va narxlar shu telefonda saqlanib qoladi.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Bekor qilish')),
        TextButton(
          onPressed: () => Navigator.of(c).pop(true),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5484D)),
          child: const Text('Chiqish'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final state = AppScope.read(context);
  final nav = Navigator.of(context);
  await state.logout();
  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const CountryScreen()),
    (_) => false,
  );
}

const _divider = Divider(height: 1, indent: 56);

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.lightMuted)),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.label, required this.value, this.color, this.onTap});

  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.lightMuted)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, this.value, this.onTap});

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.lightMuted)),
            ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.lightMuted),
        ],
      ),
      onTap: onTap,
    );
  }
}
