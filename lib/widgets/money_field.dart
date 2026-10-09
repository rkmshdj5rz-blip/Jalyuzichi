import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/orders.dart';

/// Raqamlarni "1 250 000" ko'rinishida guruhlab yozadi.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = formatNumber(double.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Summa kiritish maydoni ("so'm" qo'shimchasi bilan).
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.onChanged,
    this.suffix = "so'm",
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final ValueChanged<double>? onChanged;
  final String suffix;
  final bool autofocus;

  /// Boshlang'ich qiymat uchun matn (0 bo'lsa bo'sh).
  static String text(double v) => v == 0 ? '' : formatNumber(v);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: const [MoneyInputFormatter()],
      onChanged: (v) => onChanged?.call(parseMoney(v)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixText: suffix,
      ),
    );
  }
}
