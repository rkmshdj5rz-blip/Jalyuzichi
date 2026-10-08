import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../data/orders.dart';
import '../data/sample_orders.dart';
import '../theme.dart';
import '../widgets/order_actions.dart';
import '../widgets/order_card.dart';
import 'new_order_screen.dart';

void openNewOrder(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const NewOrderScreen()),
  );
}

void openOrder(BuildContext context, Order order) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => OrderDetailScreen(number: order.number)),
  );
}

/// Buyurtmalar bo'limining ichki sahifalari.
enum OrdersSection { orders, cash, workshop }

/// Buyurtmalar bo'limi: panel, ro'yxat, kassa jurnali.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    this.initialFilter = OrderFilter.all,
    this.initialSection = OrdersSection.orders,
    this.focusSearch = false,
  });

  final OrderFilter initialFilter;
  final OrdersSection initialSection;

  /// Qidiruv maydonini darhol ochish (bosh sahifadagi qidiruvdan).
  final bool focusSearch;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late OrdersSection _section = widget.initialSection;
  Period _period = Period.all;
  String? _branch;
  late OrderFilter _filter = widget.initialFilter;
  OrderSort _sort = OrderSort.auto;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = DateTime.now();
    final all = state.orders;
    final scoped = [
      for (final o in all)
        if ((_branch == null || o.branch == _branch) &&
            _period.contains(o.createdAt, now))
          o,
    ];

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Buyurtmalar',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4)),
                    ),
                    FilledButton.icon(
                      onPressed: () => openNewOrder(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yangi buyurtma'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Segmented<OrdersSection>(
                  value: _section,
                  items: const {
                    OrdersSection.orders: 'Buyurtmalar',
                    OrdersSection.cash: 'Kassa jurnali',
                    OrdersSection.workshop: 'Tsexdan yuklar',
                  },
                  onChanged: (v) => setState(() => _section = v),
                ),
                const SizedBox(height: 12),
                if (_section != OrdersSection.workshop) ...[
                  _Segmented<Period>(
                    value: _period,
                    items: {for (final p in Period.values) p: p.label},
                    onChanged: (v) => setState(() => _period = v),
                  ),
                  const SizedBox(height: 10),
                  _BranchPicker(
                    value: _branch,
                    onChanged: (v) => setState(() => _branch = v),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          ...switch (_section) {
            OrdersSection.orders => _ordersSlivers(all, scoped, now),
            OrdersSection.cash => [_CashJournal(orders: scoped, period: _period)],
            OrdersSection.workshop => [const _Workshop()],
          },
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  List<Widget> _ordersSlivers(List<Order> all, List<Order> scoped, DateTime now) {
    if (all.isEmpty) {
      return [const SliverToBoxAdapter(child: _Empty())];
    }
    final stats = OrderStats(scoped, now);
    final q = _query.trim().toLowerCase().replaceAll('#', '');
    final shown = sortOrders(
      [
        for (final o in scoped)
          if (_filter.test(o, now) && (q.isEmpty || _matches(o, q))) o,
      ],
      _sort,
      now,
    );

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.list(
          children: [
            _StatsPanel(
              stats: stats,
              onFilter: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in OrderFilter.values)
                  _FilterChip(
                    label: f.label,
                    count: scoped.where((o) => f.test(o, now)).length,
                    selected: _filter == f,
                    danger: f == OrderFilter.overdue,
                    onTap: () => setState(() => _filter = f),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              autofocus: widget.focusSearch,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Qidirish: mijoz, telefon, №raqam, kod',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text('${shown.length} ta buyurtma',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightMuted)),
                ),
                PopupMenuButton<OrderSort>(
                  initialValue: _sort,
                  onSelected: (v) => setState(() => _sort = v),
                  itemBuilder: (_) => [
                    for (final s in OrderSort.values)
                      PopupMenuItem(value: s, child: Text(s.label)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort_rounded, size: 20),
                        const SizedBox(width: 6),
                        Text(_sort.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      if (shown.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text("Bu filtr bo'yicha buyurtma topilmadi",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.lightMuted)),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: shown.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => OrderCard(
              order: shown[i],
              onOpen: () => openOrder(context, shown[i]),
            ),
          ),
        ),
    ];
  }

  bool _matches(Order o, String q) {
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return o.customerName.toLowerCase().contains(q) ||
        o.number.toString().contains(q) ||
        (digits.length >= 3 &&
            o.customerPhone.replaceAll(RegExp(r'\D'), '').contains(digits)) ||
        o.items.any((i) =>
            i.model.toLowerCase().contains(q) ||
            (i.type ?? '').toLowerCase().contains(q));
  }
}

/// Bir nechta variantdan birini tanlash (segmentlar).
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).inputDecorationTheme.fillColor;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final e in items.entries)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: e.key == value
                        ? Theme.of(context).colorScheme.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: e.key == value
                        ? const [
                            BoxShadow(color: Color(0x14000000), blurRadius: 6)
                          ]
                        : null,
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          e.key == value ? FontWeight.w700 : FontWeight.w500,
                      color: e.key == value ? null : AppColors.lightMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BranchPicker extends StatelessWidget {
  const _BranchPicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(14),
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.store_outlined),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Barcha filiallar')),
        for (final b in branches) DropdownMenuItem(value: b, child: Text(b)),
      ],
      onChanged: onChanged,
    );
  }
}

// Holat ranglari.
const _red = Color(0xFFE5484D);
const _amber = Color(0xFFE38B00);
const _green = Color(0xFF1E9E5A);
const _blue = Color(0xFF3B6FE0);
const _grey = Color(0xFF8A8A99);

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.stats, required this.onFilter});

  final OrderStats stats;
  final ValueChanged<OrderFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PanelTitle('Montaj'),
        const SizedBox(height: 8),
        _Grid(children: [
          _StatTile(
            icon: Icons.error_outline_rounded,
            color: _red,
            label: "Muddati o'tgan",
            value: '${stats.overdue}',
            hint: stats.overdue == 0
                ? "hammasi o'z vaqtida"
                : 'eng kech: ${stats.maxLateDays} kun',
            valueColor: stats.overdue > 0 ? _red : null,
            onTap: () => onFilter(OrderFilter.overdue),
          ),
          _StatTile(
            icon: Icons.handyman_outlined,
            color: _amber,
            label: "Bugun o'rnatiladi",
            value: '${stats.installToday}',
            hint: 'bugungi montaj',
            onTap: () => onFilter(OrderFilter.today),
          ),
          _StatTile(
            icon: Icons.event_outlined,
            color: _blue,
            label: 'Ertaga',
            value: '${stats.installTomorrow}',
            hint: 'ertangi montaj',
            onTap: () => onFilter(OrderFilter.tomorrow),
          ),
          _StatTile(
            icon: Icons.edit_calendar_outlined,
            color: _grey,
            label: 'Sana belgilanmagan',
            value: '${stats.noDate}',
            hint: 'tanlangan davrda',
            onTap: () => onFilter(OrderFilter.noDate),
          ),
        ]),
        const SizedBox(height: 18),
        const _PanelTitle('Pul'),
        const SizedBox(height: 8),
        _MoneyHero(stats: stats),
        const SizedBox(height: 10),
        _Grid(children: [
          _StatTile(
            icon: Icons.warning_amber_rounded,
            color: _red,
            label: "Qarz (o'rnatilgan, puli berilmagan)",
            value: formatMoney(stats.debt),
            hint: '${stats.debtCount} ta buyurtma',
            onTap: () => onFilter(OrderFilter.debtor),
          ),
          _StatTile(
            icon: Icons.account_balance_wallet_outlined,
            color: _amber,
            label: "Qoldiq (hali o'rnatilmagan)",
            value: formatMoney(stats.remaining),
            hint: '${stats.remainingCount} ta buyurtma',
            onTap: () => onFilter(OrderFilter.remaining),
          ),
        ]),
      ],
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.lightMuted));
  }
}

/// Ikki ustunli to'r: qator balandligi eng baland kartaga teng.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: children[i]),
            const SizedBox(width: 10),
            Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox()),
          ],
        ),
      ));
      if (i + 2 < children.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.valueColor,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.lightMuted, height: 1.2)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: valueColor,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              const Spacer(),
              Text(hint,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.lightMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asosiy pul kartasi: buyurtmalar soni, umumiy summa va to'langan qism.
class _MoneyHero extends StatelessWidget {
  const _MoneyHero({required this.stats});

  final OrderStats stats;

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.onBrand;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Umumiy summa',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${stats.count} ta buyurtma',
                    style: const TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatMoney(stats.total),
                style: const TextStyle(
                    color: ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ),
          const Text('chegirmadan keyin',
              style: TextStyle(color: ink, fontSize: 12)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stats.total == 0 ? 0 : (stats.paid / stats.total).clamp(0, 1),
              minHeight: 8,
              color: ink,
              backgroundColor: ink.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text("To'langan: ${formatMoney(stats.paid)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: ink, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text('${stats.paidPercent}%',
                  style: const TextStyle(
                      color: ink, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final int count;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).inputDecorationTheme.fillColor;
    final bg = selected
        ? AppColors.onBrand
        : danger && count > 0
            ? _red.withValues(alpha: 0.1)
            : fill;
    final fg = selected
        ? Colors.white
        : danger && count > 0
            ? _red
            : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected && isDark ? AppColors.brand : bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected && isDark ? AppColors.onBrand : fg)),
              const SizedBox(width: 6),
              Text('$count',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: (selected && isDark ? AppColors.onBrand : fg)
                              ?.withValues(alpha: 0.7) ??
                          AppColors.lightMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.receipt_long_rounded, size: 36),
          ),
          const SizedBox(height: 16),
          const Text("Hali buyurtma yo'q",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            "Birinchi buyurtmani \"Yangi buyurtma\" tugmasi bilan qo'shing. "
            "Panel qanday ishlashini ko'rish uchun namuna buyurtmalarni ham qo'shishingiz mumkin.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.lightMuted, height: 1.35),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              final state = AppScope.read(context);
              state.addOrders(
                  sampleOrders(DateTime.now(), state.nextOrderNumber));
            },
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text("Namuna buyurtmalarni qo'shish"),
          ),
        ],
      ),
    );
  }
}

/// Kassa jurnali: tanlangan davrdagi barcha to'lovlar.
class _CashJournal extends StatelessWidget {
  const _CashJournal({required this.orders, required this.period});

  final List<Order> orders;
  final Period period;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Kassa to'lov kuni bo'yicha olinadi, buyurtma kuni bo'yicha emas.
    final allOrders = AppScope.of(context).orders;
    final branchSet = orders.map((o) => o.branch).toSet();
    final rows = [
      for (final o in allOrders)
        if (orders.isEmpty || branchSet.contains(o.branch))
          for (final p in o.payments)
            if (period.contains(p.date, now)) (order: o, payment: p),
    ]..sort((a, b) => b.payment.date.compareTo(a.payment.date));
    final total = rows.fold<double>(0, (a, r) => a + r.payment.amount);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.list(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kassaga tushgan · ${period.label.toLowerCase()}',
                    style: const TextStyle(
                        color: AppColors.onBrand, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(formatMoney(total),
                    style: const TextStyle(
                        color: AppColors.onBrand,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
                Text("${rows.length} ta to'lov",
                    style: const TextStyle(color: AppColors.onBrand)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text("Bu davrda to'lov yo'q",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.lightMuted)),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 64),
                    ListTile(
                      onTap: () => openOrder(context, rows[i].order),
                      leading: CircleAvatar(
                        backgroundColor: _green.withValues(alpha: 0.12),
                        child: const Icon(Icons.south_west_rounded,
                            color: _green, size: 20),
                      ),
                      title: Text(rows[i].order.customerLabel,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '№ ${rows[i].order.number} · ${formatDay(rows[i].payment.date)}'),
                      trailing: Text('+${formatMoney(rows[i].payment.amount)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: _green)),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Workshop extends StatelessWidget {
  const _Workshop();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(32, 40, 32, 32),
        child: Column(
          children: [
            Icon(Icons.local_shipping_outlined,
                size: 48, color: AppColors.lightMuted),
            SizedBox(height: 12),
            Text('Tsexdan yuklar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text(
              "Bu bo'lim tez orada qo'shiladi: tsexdan filiallarga jo'natilgan tayyor mahsulotlar shu yerda ko'rinadi.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.lightMuted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String title, String text) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Bekor qilish')),
        TextButton(
          onPressed: () => Navigator.of(c).pop(true),
          style: TextButton.styleFrom(foregroundColor: _red),
          child: const Text("O'chirish"),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<void> _confirmDelete(BuildContext context, Order order) async {
  final ok = await _confirm(context, "Buyurtmani o'chirasizmi?",
      "№ ${order.number} · ${order.customerLabel}. Uni qaytarib bo'lmaydi.");
  if (!ok || !context.mounted) return;
  final state = AppScope.read(context);
  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).pop();
  await state.deleteOrder(order.number);
  messenger.showSnackBar(
      SnackBar(content: Text("Buyurtma № ${order.number} o'chirildi")));
}

/// Buyurtmaning to'liq ma'lumoti.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final order =
        state.orders.where((o) => o.number == number).firstOrNull;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Buyurtma topilmadi')),
      );
    }

    Widget row(String label, String value, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(label,
                    style: const TextStyle(color: AppColors.lightMuted)),
              ),
              Expanded(
                child: Text(value,
                    style: TextStyle(fontWeight: FontWeight.w600, color: color)),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('Buyurtma № ${order.number}'),
        actions: [
          IconButton(
            tooltip: 'Tahrirlash',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => NewOrderScreen(editing: order))),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') await _confirmDelete(context, order);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline_rounded, color: _red),
                  title: Text("Buyurtmani o'chirish",
                      style: TextStyle(color: _red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          OrderCard(order: order),
          if (order.customerPhone.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri(
                  scheme: 'tel',
                  path: order.customerPhone.replaceAll(' ', ''))),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.call_outlined),
              label: Text("Qo'ng'iroq qilish · ${order.customerPhone}"),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  row('Filial', order.branch),
                  row('Buyurtmachi', order.customerLabel),
                  if (order.customerPhone.isNotEmpty)
                    row('Telefon', order.customerPhone),
                  if (order.address.isNotEmpty) row('Manzil', order.address),
                  if (order.installDate != null)
                    row('Montaj sanasi', formatDate(order.installDate!)),
                  if (order.note.isNotEmpty) row('Izoh', order.note),
                  row('Kiritilgan', formatDate(order.createdAt)),
                  if (order.discount > 0)
                    row('Chegirma', formatMoney(order.discount)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in order.items) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        [item.type ?? '', if (item.model.isNotEmpty) item.model]
                            .join(' · '),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    if (item.pricePerM2 > 0)
                      Text('1 m² · ${formatMoney(item.pricePerM2)}',
                          style: const TextStyle(color: AppColors.lightMuted)),
                    const SizedBox(height: 8),
                    for (final s in item.validSizes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                            '${formatArea(s.width)} × ${formatArea(s.height)} sm  ·  ${s.count} dona  ·  ${formatArea(s.area)} m²'),
                      ),
                    if (item.pricePerM2 > 0) ...[
                      const Divider(),
                      Text('${formatArea(item.area)} m² · ${formatMoney(item.sum)}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (order.payments.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text("To'lovlar",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Card(
              child: Column(
                children: [
                  for (final p in order.payments)
                    ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: Text(formatMoney(p.amount),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(formatDate(p.date)),
                      trailing: IconButton(
                        tooltip: "To'lovni o'chirish",
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () async {
                          final ok = await _confirm(context,
                              "To'lovni o'chirasizmi?", formatMoney(p.amount));
                          if (!ok) return;
                          order.payments.remove(p);
                          await state.updateOrder(order);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showMontajSheet(context, order),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.handyman_outlined),
                  label: const Text('Montaj'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: order.remaining > 0
                      ? () => showPaymentDialog(context, order)
                      : null,
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(order.remaining > 0 ? "To'lov" : "To'langan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
