import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/orders.dart';
import '../theme.dart';
import 'new_order_screen.dart';

/// Buyurtmalar ro'yxati va "+ Buyurtma" tugmasi.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = AppScope.of(context).orders;
    return Scaffold(
      appBar: AppBar(title: const Text('Buyurtmalar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openNewOrder(context),
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onBrand,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buyurtma',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: orders.isEmpty
          ? const _Empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OrderCard(order: orders[i]),
            ),
    );
  }
}

void openNewOrder(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const NewOrderScreen()),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              "Birinchi buyurtmani qo'shish uchun pastdagi \"+ Buyurtma\" tugmasini bosing",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.lightMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final types = order.items.map((i) => i.type).whereType<String>().toSet();
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('№ ${order.number}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  const _StatusChip(),
                  Expanded(
                    child: Text(formatDate(order.createdAt),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.lightMuted)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(order.customerLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(types.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.lightMuted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.straighten_rounded,
                      size: 18, color: AppColors.lightMuted),
                  const SizedBox(width: 6),
                  Text("${order.sizeCount} o'lcham · ${formatArea(order.area)} m²",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(order.branch,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.lightMuted)),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Yangi',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.onBrand)),
    );
  }
}

/// Buyurtmaning to'liq ma'lumoti.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value) => Padding(
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
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text('Buyurtma № ${order.number}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
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
                    row("O'rnatish sanasi", formatDate(order.installDate!)),
                  if (order.note.isNotEmpty) row('Izoh', order.note),
                  row('Kiritilgan', formatDate(order.createdAt)),
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
                    Text(item.type ?? '',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final s in item.validSizes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                            '${formatArea(s.width)} × ${formatArea(s.height)} sm  ·  ${s.count} dona  ·  ${formatArea(s.area)} m²'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text("Jami: ${order.sizeCount} o'lcham · ${formatArea(order.area)} m²",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
