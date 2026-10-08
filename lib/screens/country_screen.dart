import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/countries.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import 'phone_screen.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  Country _selected = countries.first;

  Future<void> _continue() async {
    await AppScope.read(context).setCountry(_selected.code);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhoneScreen(country: _selected)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                children: [
                  const Center(child: AppLogo(size: 80)),
                  const SizedBox(height: 32),
                  const Text(
                    'Davlatni tanlang',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  for (final c in countries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CountryTile(
                        country: c,
                        selected: c == _selected,
                        onTap: () => setState(() => _selected = c),
                      ),
                    ),
                  Material(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      leading: const Icon(Icons.public_rounded, size: 28),
                      title: const Text('Boshqa davlatlar'),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Tez orada boshqa davlatlar qo'shiladi")),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton(
                onPressed: _continue,
                child: const Text('Davom etish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final Country country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
        leading: Text(country.flag, style: const TextStyle(fontSize: 26)),
        title: Text(country.name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(country.code),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : AppColors.lightMuted,
        ),
      ),
    );
  }
}
