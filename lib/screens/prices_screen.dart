import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/orders.dart';
import '../theme.dart';
import '../widgets/money_field.dart';

const _icons = {
  'Vertikal jalyuzi': Icons.view_week_rounded,
  'Gorizontal jalyuzi': Icons.view_headline_rounded,
  'Rulonli parda': Icons.view_day_rounded,
  'Kun-tun (zebra) parda': Icons.view_stream_rounded,
  'Plisse parda': Icons.unfold_less_rounded,
  'Rim pardasi': Icons.view_agenda_rounded,
};

/// Narxlar: 1 m² narxlari va tez hisoblash. Yangi buyurtmada narx
/// shu yerdan avtomatik qo'yiladi.
class PricesScreen extends StatelessWidget {
  const PricesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final prices = state.prices;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('Narxlar',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          const Text(
              "1 m² uchun. Yangi buyurtmada narx shu yerdan o'zi qo'yiladi.",
              style: TextStyle(color: AppColors.lightMuted)),
          const SizedBox(height: 16),
          _Calculator(prices: prices),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                for (final t in productTypes) ...[
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icons[t] ?? Icons.blinds_rounded, size: 22),
                    ),
                    title: Text(t,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${formatMoney(prices[t]!)} / m²'),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _edit(context, t, prices[t]!),
                  ),
                  if (t != productTypes.last)
                    const Divider(height: 1, indent: 74),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, String type, double price) async {
    final state = AppScope.read(context);
    final controller = TextEditingController(text: MoneyField.text(price));
    final value = await showDialog<double>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(type),
        content: MoneyField(
          controller: controller,
          autofocus: true,
          label: '1 m² narxi',
          suffix: "so'm",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Bekor qilish')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(c).pop(parseMoney(controller.text)),
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await state.setPrice(type, value);
  }
}

/// Mijoz telefonda so'raganda tez narx aytish uchun.
class _Calculator extends StatefulWidget {
  const _Calculator({required this.prices});

  final Map<String, double> prices;

  @override
  State<_Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<_Calculator> {
  String _type = productTypes.first;
  double _w = 0, _h = 0;
  int _n = 1;

  @override
  Widget build(BuildContext context) {
    final area = _w * _h / 10000 * _n;
    final sum = area * (widget.prices[_type] ?? 0);
    double parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        );
    final numberInput = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Theme(
        // Limon fonda maydonlar oq bo'ladi.
        data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
                fillColor: Colors.white,
                hintStyle: const TextStyle(color: AppColors.lightMuted),
              ),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.onBrand),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate_outlined, color: AppColors.onBrand),
                  SizedBox(width: 8),
                  Text('Tez hisoblash',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: AppColors.onBrand),
                borderRadius: BorderRadius.circular(14),
                items: [
                  for (final t in productTypes)
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.onBrand),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: numberInput,
                      decoration: deco('eni, sm'),
                      onChanged: (v) => setState(() => _w = parse(v)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('×', style: TextStyle(fontSize: 16)),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.onBrand),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: numberInput,
                      decoration: deco("bo'yi, sm"),
                      onChanged: (v) => setState(() => _h = parse(v)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('=', style: TextStyle(fontSize: 16)),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: '1',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.onBrand),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: deco('soni'),
                      onChanged: (v) =>
                          setState(() => _n = int.tryParse(v) ?? 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text('${formatArea(area)} m²',
                        style: TextStyle(
                            color: AppColors.onBrand.withValues(alpha: 0.7))),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(formatMoney(sum),
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
