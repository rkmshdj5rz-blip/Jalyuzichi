import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/address_sheet.dart';
import '../widgets/app_logo.dart';
import '../widgets/side_menu.dart';
import '../data/orders.dart';
import 'cabinet_screen.dart';
import 'orders_screen.dart';
import 'prices_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Bosh ekrandan boshqa bo'limni ochish uchun.
typedef OpenOrders = void Function(
    {OrderFilter filter, OrdersSection section, bool search});

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  // Buyurtmalar bo'limi qaysi filtr bilan ochilishi.
  int _ordersVersion = 0;
  OrderFilter _filter = OrderFilter.all;
  OrdersSection _section = OrdersSection.orders;
  bool _search = false;

  @override
  void initState() {
    super.initState();
    // Birinchi kirishda manzilni so'raymiz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !AppScope.read(context).hasAddress) {
        showAddressSheet(context);
      }
    });
  }

  void _openOrders({
    OrderFilter filter = OrderFilter.all,
    OrdersSection section = OrdersSection.orders,
    bool search = false,
  }) {
    setState(() {
      _filter = filter;
      _section = section;
      _search = search;
      _ordersVersion++;
      _tab = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      drawer: _tab == 0
          ? SideMenu(
              onTab: (i) => setState(() => _tab = i),
              onOrders: _openOrders,
            )
          : null,
      appBar: _tab == 0
          ? AppBar(
              titleSpacing: 0,
              title: const Row(
                children: [
                  AppLogo(size: 30, showName: false),
                  SizedBox(width: 10),
                  Text('Jalyuzichi'),
                ],
              ),
              actions: [_Bell(state: state)],
            )
          : null,
      body: switch (_tab) {
        0 => _HomeBody(state: state, openOrders: _openOrders,
            openTab: (i) => setState(() => _tab = i)),
        1 => OrdersScreen(
            key: ValueKey(_ordersVersion),
            initialFilter: _filter,
            initialSection: _section,
            focusSearch: _search,
          ),
        2 => const PricesScreen(),
        _ => CabinetScreen(onOpenOrders: () => _openOrders()),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          if (i == 1 && _tab != 1) {
            _filter = OrderFilter.all;
            _section = OrdersSection.orders;
            _search = false;
          }
          _tab = i;
        }),
        indicatorColor: AppColors.brand.withValues(alpha: 0.6),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
                icon: Icon(t.$1), selectedIcon: Icon(t.$2), label: t.$3),
        ],
      ),
    );
  }
}

const _tabs = [
  (Icons.home_outlined, Icons.home_rounded, 'Bosh sahifa'),
  (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Buyurtmalar'),
  (Icons.sell_outlined, Icons.sell_rounded, 'Narxlar'),
  (Icons.person_outline_rounded, Icons.person_rounded, 'Kabinet'),
];

void _soon(BuildContext context, String what) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("$what bo'limi tez orada qo'shiladi")),
  );
}

/// Muddati o'tgan, bugungi va ertangi montajlar.
List<Order> _reminders(List<Order> orders, DateTime now) => sortOrders(
      [
        for (final o in orders)
          if (!o.isInstalled && (o.daysToInstall(now) ?? 99) <= 1) o,
      ],
      OrderSort.install,
      now,
    );

class _Bell extends StatelessWidget {
  const _Bell({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final list = _reminders(state.orders, now);
    final urgent = list.where((o) => (o.daysToInstall(now) ?? 1) <= 0).length;
    return IconButton(
      tooltip: 'Eslatmalar',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (c) => _RemindersSheet(orders: list),
      ),
      icon: Badge(
        isLabelVisible: urgent > 0,
        label: Text('$urgent'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}

class _RemindersSheet extends StatelessWidget {
  const _RemindersSheet({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Eslatmalar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            if (orders.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Text(
                    "Bugun va ertaga montaj yo'q, muddati o'tgan buyurtma ham yo'q.",
                    style: TextStyle(color: AppColors.lightMuted)),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  children: [
                    for (final o in orders)
                      _MontajRow(
                        order: o,
                        now: now,
                        onTap: () {
                          Navigator.of(context).pop();
                          openOrder(context, o);
                        },
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

/// Montaj ro'yxatidagi ixcham qator.
class _MontajRow extends StatelessWidget {
  const _MontajRow({required this.order, required this.now, this.onTap});

  final Order order;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final d = order.daysToInstall(now)!;
    final (text, color) = d < 0
        ? ('${-d} kun kechikdi', const Color(0xFFE5484D))
        : d == 0
            ? ('Bugun', const Color(0xFFE38B00))
            : d == 1
                ? ('Ertaga', const Color(0xFF3B6FE0))
                : (formatDay(order.installDate!), AppColors.lightMuted);
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.handyman_outlined, color: color, size: 22),
      ),
      title: Text('№ ${order.number} · ${order.customerLabel}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
          order.address.isEmpty ? order.branch : order.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: Text(text,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody(
      {required this.state, required this.openOrders, required this.openTab});

  final AppState state;
  final OpenOrders openOrders;
  final ValueChanged<int> openTab;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final orders = state.orders;
    final upcoming = sortOrders(
      [
        for (final o in orders)
          if (!o.isInstalled && o.installDate != null) o,
      ],
      OrderSort.install,
      now,
    ).take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _AddressChip(state: state),
        const SizedBox(height: 12),
        TextField(
          readOnly: true,
          onTap: () => openOrders(search: true),
          decoration: const InputDecoration(
            hintText: 'Buyurtma qidirish: mijoz, telefon, №',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 16),
        const _BannerCarousel(),
        const SizedBox(height: 16),
        _TodayCard(
          stats: OrderStats(orders, now),
          empty: orders.isEmpty,
          openOrders: openOrders,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => openNewOrder(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yangi buyurtma'),
        ),
        const SizedBox(height: 24),
        const Text("Bo'limlar",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _CategoryTile(
              title: 'Buyurtmalar',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF6A35FF),
              badge: orders.isEmpty ? null : '${orders.length}',
              onTap: () => openOrders(),
            ),
            _CategoryTile(
              title: 'Kassa jurnali',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF00A86B),
              onTap: () => openOrders(section: OrdersSection.cash),
            ),
            _CategoryTile(
              title: 'Mahsulot narxlari',
              icon: Icons.sell_rounded,
              color: const Color(0xFFFF7A00),
              onTap: () => openTab(2),
            ),
            _CategoryTile(
              title: 'Tsexdan yuklar',
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF1E88E5),
              onTap: () => openOrders(section: OrdersSection.workshop),
            ),
            _CategoryTile(
              title: "Dilerlar va do'konlar",
              icon: Icons.storefront_rounded,
              color: const Color(0xFFE91E63),
              onTap: () => _soon(context, "Dilerlar va do'konlar"),
            ),
            _CategoryTile(
              title: 'Omborxona',
              icon: Icons.warehouse_rounded,
              color: const Color(0xFF795548),
              onTap: () => _soon(context, 'Omborxona'),
            ),
          ],
        ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text('Yaqin montajlar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: () => openOrders(filter: OrderFilter.waiting),
                child: const Text('Hammasi'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final o in upcoming)
                    _MontajRow(
                        order: o, now: now, onTap: () => openOrder(context, o)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bugungi ish: montajlar va qarzlar.
class _TodayCard extends StatelessWidget {
  const _TodayCard(
      {required this.stats, required this.empty, required this.openOrders});

  final OrderStats stats;
  final bool empty;
  final OpenOrders openOrders;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF23252E) : AppColors.onBrand;
    const fg = Colors.white;
    Widget cell(String label, int value, OrderFilter f, {bool alert = false}) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => openOrders(filter: f),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: alert && value > 0
                            ? const Color(0xFFFF6B6F)
                            : AppColors.brand)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: fg.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const Text('Montaj',
                    style: TextStyle(
                        color: fg, fontSize: 17, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(formatDay(DateTime.now()),
                    style: TextStyle(color: fg.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (empty)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
              child: Text(
                  "Buyurtma kiritilgach, bu yerda bugungi va ertangi montajlar ko'rinadi.",
                  style: TextStyle(color: fg.withValues(alpha: 0.7))),
            )
          else ...[
            Row(
              children: [
                cell('Bugun', stats.installToday, OrderFilter.today),
                cell('Ertaga', stats.installTomorrow, OrderFilter.tomorrow),
                cell("Kechikkan", stats.overdue, OrderFilter.overdue,
                    alert: true),
              ],
            ),
            if (stats.debt > 0) ...[
              Divider(color: fg.withValues(alpha: 0.12), height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => openOrders(filter: OrderFilter.debtor),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 18, color: Color(0xFFFF6B6F)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            'Qarzlar: ${formatMoney(stats.debt)} · ${stats.debtCount} ta',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: fg, fontWeight: FontWeight.w600)),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: fg.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AddressChip extends StatelessWidget {
  const _AddressChip({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final text = state.hasAddress
        ? '${state.region}, ${state.district}'
        : 'Manzilni kiriting';
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => showAddressSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _Banner {
  const _Banner(this.title, this.subtitle, this.icon, this.colors,
      [this.fg = Colors.white]);

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Color fg;
}

const _banners = [
  _Banner('Barcha turdagi jalyuzilar', "Vertikal, gorizontal va rulonli",
      Icons.blinds_rounded, [AppColors.brandLight, AppColors.brandDark],
      AppColors.onBrand),
  _Banner('Bepul o\'lchov xizmati', 'Usta uyingizga o\'zi keladi',
      Icons.straighten_rounded, [Color(0xFFFF8A3D), Color(0xFFFF4D6D)]),
  _Banner('Rulonli pardalarga -20%', 'Faqat shu oy davomida',
      Icons.local_offer_rounded, [Color(0xFF14B8A6), Color(0xFF0E7490)]),
];

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % _banners.length,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final b = _banners[i];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: b.colors),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(b.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: b.fg,
                                  fontSize: 21,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(b.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: b.fg.withValues(alpha: 0.9))),
                        ],
                      ),
                    ),
                    Icon(b.icon,
                        size: 84, color: b.fg.withValues(alpha: 0.9)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page
                      ? AppColors.brand
                      : AppColors.lightMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge!,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onBrand)),
                    ),
                ],
              ),
              const Spacer(),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
