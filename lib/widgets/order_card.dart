import 'package:flutter/material.dart';

import '../data/orders.dart';
import '../theme.dart';
import 'order_actions.dart';

// Holat ranglari (brend rangidan alohida).
const _red = Color(0xFFE5484D);
const _amber = Color(0xFFE38B00);
const _green = Color(0xFF1E9E5A);
const _blue = Color(0xFF3B6FE0);

/// Ro'yxatdagi buyurtma kartasi: mijoz, mahsulotlar, pul va montaj holati.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.onOpen});

  final Order order;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = order.daysToInstall(now);
    final (statusText, statusColor) = order.isInstalled
        ? ("O'rnatilgan", _green)
        : order.isOverdue(now)
            ? ("Muddati o'tgan · ${-days!} kun", _red)
            : ("O'rnatilmagan · kutilmoqda", _amber);
    final banner = order.isInstalled
        ? null
        : switch (days) {
            0 => ("Bugun o'rnatiladi", Icons.today_rounded),
            1 => ("Ertaga o'rnatiladi", Icons.event_rounded),
            _ => null,
          };
    final surface = Theme.of(context).colorScheme.surface;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (banner != null)
              Container(
                color: AppColors.brand,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(banner.$2, size: 18, color: AppColors.onBrand),
                    const SizedBox(width: 8),
                    Text(banner.$1,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBrand)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('№ ${order.number}',
                                style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                                '${formatDay(order.createdAt)} · ${order.branch}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.lightMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                          child: _Pill(text: statusText, color: statusColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(order.customerLabel,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  if (order.customerPhone.isNotEmpty)
                    Text(order.customerPhone,
                        style: const TextStyle(color: AppColors.lightMuted)),
                  const SizedBox(height: 10),
                  for (final i in order.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Tag(
                              text: [
                            (i.type ?? '').toUpperCase(),
                            if (i.model.isNotEmpty) i.model.toUpperCase(),
                          ].join(' · ')),
                          Text(
                              '${i.sizeCount} dona · ${formatArea(i.area)} m²',
                              style: const TextStyle(
                                  color: AppColors.lightMuted)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Money('Umumiy summa', order.total, null),
                      _Money("To'langan", order.paid, _green),
                      _Money('Qoldiq', order.remaining,
                          order.remaining > 0 ? _amber : _green),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _PaidBar(order: order),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _MontajLabel(order: order)),
                      const SizedBox(width: 8),
                      _SmallButton(
                        icon: Icons.event_outlined,
                        label: 'Montaj',
                        onTap: () => showMontajSheet(context, order),
                      ),
                      if (order.remaining > 0) ...[
                        const SizedBox(width: 8),
                        _SmallButton(
                          icon: Icons.payments_outlined,
                          label: "To'lov",
                          onTap: () => showPaymentDialog(context, order),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3)),
    );
  }
}

class _Money extends StatelessWidget {
  const _Money(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatMoney(value),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ],
      ),
    );
  }
}

class _PaidBar extends StatelessWidget {
  const _PaidBar({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final ratio = order.total == 0 ? 0.0 : order.paid / order.total;
    final (text, color) = order.isPaid
        ? ("To'langan", _green)
        : order.paid == 0
            ? ("To'lanmagan", _red)
            : ("Qisman to'langan", _amber);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 6,
              color: _green,
              backgroundColor: AppColors.lightMuted.withValues(alpha: 0.18),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$text · ${(ratio * 100).round()}%',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _MontajLabel extends StatelessWidget {
  const _MontajLabel({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final (text, color) = order.isInstalled
        ? ("O'rnatildi · ${formatDay(order.installedAt!)}", _green)
        : order.installDate == null
            ? ('Montaj sanasi yo\'q', AppColors.lightMuted)
            : ('Montaj · ${formatDay(order.installDate!)}', _blue);
    return Row(
      children: [
        Icon(Icons.handyman_outlined, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: BorderSide(color: AppColors.lightMuted.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
