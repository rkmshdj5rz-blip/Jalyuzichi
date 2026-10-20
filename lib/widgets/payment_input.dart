import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/orders.dart';
import '../theme.dart';
import 'money_field.dart';

/// Kiritilayotgan to'lov: usul va summa.
class PaymentDraft {
  PaymentDraft({this.sum = 0, this.rate = 12800});

  PayMethod method = PayMethod.cash;

  /// Naqd yoki karta summasi, so'mda.
  double sum;
  double usd = 0;
  double rate;

  /// So'mdagi qiymati.
  double get amount =>
      method == PayMethod.dollar ? (usd * rate).roundToDouble() : sum;

  Payment toPayment(DateTime date) => Payment(
        amount: amount,
        date: date,
        method: method,
        usd: method == PayMethod.dollar ? usd : null,
        rate: method == PayMethod.dollar ? rate : null,
      );
}

const _methodIcons = {
  PayMethod.cash: Icons.payments_outlined,
  PayMethod.card: Icons.credit_card_rounded,
  PayMethod.dollar: Icons.attach_money_rounded,
};

/// To'lov usulini tanlash (naqd, karta, dollar) va summani kiritish.
class PaymentInput extends StatefulWidget {
  const PaymentInput({
    super.key,
    required this.draft,
    required this.onChanged,
    this.label = 'Summa',
    this.autofocus = false,
  });

  final PaymentDraft draft;
  final VoidCallback onChanged;
  final String label;
  final bool autofocus;

  @override
  State<PaymentInput> createState() => PaymentInputState();
}

class PaymentInputState extends State<PaymentInput> {
  late final _sum = TextEditingController(text: MoneyField.text(widget.draft.sum));
  final _usd = TextEditingController();
  late final _rate =
      TextEditingController(text: MoneyField.text(widget.draft.rate));

  PaymentDraft get d => widget.draft;

  /// Summani tashqaridan qo'yish (masalan "To'liq" tugmasi).
  void setSum(double v) {
    if (d.method == PayMethod.dollar) {
      d.usd = d.rate == 0 ? 0 : (v / d.rate * 100).round() / 100;
      _usd.text = d.usd == 0 ? '' : _usdText(d.usd);
    } else {
      d.sum = v;
      _sum.text = MoneyField.text(v);
    }
    setState(() {});
    widget.onChanged();
  }

  static String _usdText(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

  @override
  void dispose() {
    _sum.dispose();
    _usd.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).inputDecorationTheme.fillColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              for (final m in PayMethod.values)
                Expanded(
                  child: GestureDetector(
                    key: ValueKey('pay-${m.name}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() => d.method = m);
                      widget.onChanged();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: d.method == m
                            ? AppColors.brand
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_methodIcons[m],
                              size: 18,
                              color: d.method == m
                                  ? AppColors.onBrand
                                  : AppColors.lightMuted),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(m.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: d.method == m
                                        ? AppColors.onBrand
                                        : AppColors.lightMuted)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (d.method != PayMethod.dollar)
          MoneyField(
            controller: _sum,
            label: widget.label,
            autofocus: widget.autofocus,
            icon: _methodIcons[d.method],
            onChanged: (v) {
              d.sum = v;
              widget.onChanged();
            },
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _usd,
                  autofocus: widget.autofocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,7}([.,]\d{0,2})?')),
                  ],
                  onChanged: (v) {
                    d.usd = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                    setState(() {});
                    widget.onChanged();
                  },
                  decoration: InputDecoration(
                    labelText: widget.label,
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    suffixText: '\$',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MoneyField(
                  controller: _rate,
                  label: 'Kurs',
                  suffix: "so'm",
                  onChanged: (v) {
                    d.rate = v;
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          if (d.usd > 0) ...[
            const SizedBox(height: 6),
            Text('= ${formatMoney(d.amount)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ],
      ],
    );
  }
}
