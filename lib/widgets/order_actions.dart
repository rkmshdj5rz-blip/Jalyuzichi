import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/orders.dart';
import '../theme.dart';
import 'money_field.dart';

/// Montaj: sanani belgilash yoki o'rnatildi deb belgilash.
Future<void> showMontajSheet(BuildContext context, Order order) {
  final state = AppScope.read(context);
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Montaj · № ${order.number}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              order.isInstalled
                  ? "O'rnatilgan: ${formatDay(order.installedAt!)}"
                  : order.installDate == null
                      ? 'Sana belgilanmagan'
                      : 'Montaj sanasi: ${formatDay(order.installDate!)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.lightMuted),
            ),
            const SizedBox(height: 12),
            if (!order.isInstalled) ...[
              _SheetAction(
                icon: Icons.check_circle_rounded,
                title: "O'rnatildi deb belgilash",
                primary: true,
                onTap: () async {
                  order.installedAt = DateTime.now();
                  await state.updateOrder(order);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  messenger.showSnackBar(SnackBar(
                      content: Text("№ ${order.number} o'rnatildi")));
                },
              ),
              _SheetAction(
                icon: Icons.event_outlined,
                title: order.installDate == null
                    ? 'Montaj sanasini belgilash'
                    : "Sanani o'zgartirish",
                onTap: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: sheetContext,
                    initialDate: order.installDate ?? now,
                    firstDate: now.subtract(const Duration(days: 365)),
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (d == null) return;
                  await state.updateOrder(order.copyWith(installDate: d));
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
              if (order.installDate != null)
                _SheetAction(
                  icon: Icons.event_busy_outlined,
                  title: 'Sanani olib tashlash',
                  onTap: () async {
                    await state
                        .updateOrder(order.copyWith(clearInstallDate: true));
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                ),
            ] else
              _SheetAction(
                icon: Icons.undo_rounded,
                title: "O'rnatilmagan deb qaytarish",
                onTap: () async {
                  order.installedAt = null;
                  await state.updateOrder(order);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        tileColor: primary
            ? AppColors.brand
            : Theme.of(context).inputDecorationTheme.fillColor,
        textColor: primary ? AppColors.onBrand : null,
        iconColor: primary ? AppColors.onBrand : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: onTap,
      ),
    );
  }
}

/// To'lov qo'shish. Summa oldindan qoldiq bilan to'ldirilgan.
Future<void> showPaymentDialog(BuildContext context, Order order) async {
  final state = AppScope.read(context);
  final messenger = ScaffoldMessenger.of(context);
  final amount = await showDialog<double>(
    context: context,
    builder: (_) => _PaymentDialog(order: order),
  );
  if (amount == null || amount <= 0) return;
  order.payments.add(Payment(amount: amount, date: DateTime.now()));
  await state.updateOrder(order);
  messenger.showSnackBar(SnackBar(
      content: Text("№ ${order.number}: ${formatMoney(amount)} qabul qilindi")));
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.order});

  final Order order;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final _controller =
      TextEditingController(text: MoneyField.text(widget.order.remaining));
  late double _amount = widget.order.remaining;

  void _set(double v) {
    _controller.text = MoneyField.text(v);
    setState(() => _amount = v);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.order.remaining;
    final over = _amount > remaining;
    return AlertDialog(
      title: Text("To'lov · № ${widget.order.number}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Qoldiq: ${formatMoney(remaining)}',
              style: const TextStyle(color: AppColors.lightMuted)),
          const SizedBox(height: 12),
          MoneyField(
            controller: _controller,
            autofocus: true,
            hint: 'Summa',
            onChanged: (v) => setState(() => _amount = v),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                  label: const Text("To'liq"), onPressed: () => _set(remaining)),
              ActionChip(
                  label: const Text('Yarmi'),
                  onPressed: () => _set((remaining / 2).roundToDouble())),
            ],
          ),
          if (over) ...[
            const SizedBox(height: 8),
            const Text("Summa qoldiqdan ko'p",
                style: TextStyle(color: Color(0xFFE5484D))),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: _amount > 0 && !over
              ? () => Navigator.of(context).pop(_amount)
              : null,
          child: const Text('Saqlash'),
        ),
      ],
    );
  }
}
