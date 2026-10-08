import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/address_sheet.dart';
import '../widgets/app_logo.dart';
import '../widgets/side_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

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

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      drawer: const SideMenu(),
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(
          children: [
            AppLogo(size: 30, showName: false),
            SizedBox(width: 10),
            Text('Jalyuzichi'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _soon(context, 'Bildirishnomalar'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: _tab == 0
          ? _HomeBody(state: state)
          : _Placeholder(title: _tabs[_tab].$2),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        indicatorColor: AppColors.brand.withValues(alpha: 0.25),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: Icon(t.$1), label: t.$2),
        ],
      ),
    );
  }
}

const _tabs = [
  (Icons.home_rounded, 'Bosh sahifa'),
  (Icons.grid_view_rounded, 'Katalog'),
  (Icons.shopping_bag_outlined, 'Savat'),
  (Icons.person_outline_rounded, 'Kabinet'),
];

void _soon(BuildContext context, String what) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("$what bo'limi tez orada qo'shiladi")),
  );
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _AddressChip(state: state),
        const SizedBox(height: 12),
        TextField(
          readOnly: true,
          onTap: () => _soon(context, 'Qidiruv'),
          decoration: const InputDecoration(
            hintText: 'Mahsulot yoki xizmat qidirish',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 16),
        const _BannerCarousel(),
        const SizedBox(height: 24),
        const Text('Xizmatlar',
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
            for (final c in _categories) _CategoryTile(category: c),
          ],
        ),
      ],
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
                              style: TextStyle(
                                  color: b.fg,
                                  fontSize: 21,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(b.subtitle,
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

class _Category {
  const _Category(this.title, this.icon, this.color);

  final String title;
  final IconData icon;
  final Color color;
}

const _categories = [
  _Category('Buyurtmalar', Icons.receipt_long_rounded, Color(0xFF6A35FF)),
  _Category('Mahsulot narxlari', Icons.sell_rounded, Color(0xFFFF7A00)),
  _Category("Dilerlar va do'konlar", Icons.storefront_rounded, Color(0xFF00A86B)),
  _Category('Yangi buyurtma', Icons.add_box_rounded, Color(0xFF1E88E5)),
  _Category('Savat', Icons.shopping_cart_rounded, Color(0xFFE91E63)),
  _Category('Omborxona', Icons.warehouse_rounded, Color(0xFF795548)),
];

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final _Category category;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _soon(context, category.title),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(category.icon, color: category.color, size: 26),
              ),
              const Spacer(),
              Text(category.title,
                  maxLines: 2,
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

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_rounded,
              size: 56, color: AppColors.lightMuted),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text("Bu bo'lim tez orada qo'shiladi",
              style: TextStyle(color: AppColors.lightMuted)),
        ],
      ),
    );
  }
}
