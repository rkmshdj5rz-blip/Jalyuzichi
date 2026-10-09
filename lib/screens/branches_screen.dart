import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/branches.dart';
import '../data/orders.dart';
import '../theme.dart';

const _red = Color(0xFFE5484D);
const _green = Color(0xFF1E9E5A);

IconData _icon(BranchKind k) => switch (k) {
  BranchKind.branch => Icons.store_rounded,
  BranchKind.shop => Icons.storefront_rounded,
  BranchKind.workshop => Icons.precision_manufacturing_rounded,
  BranchKind.warehouse => Icons.warehouse_rounded,
};

/// Filiallar ro'yxati: qo'shish, sozlash, o'chirish.
class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = DateTime.now();
    final all = state.branches;
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final b in all)
        if (q.isEmpty ||
            b.name.toLowerCase().contains(q) ||
            b.address.toLowerCase().contains(q))
          b,
    ];
    final orders = state.orders;
    final mainId = state.mainBranch?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Filiallar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openBranchEdit(context, null),
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onBrand,
        elevation: 2,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Filial qo'shish"),
      ),
      body: all.isEmpty
          ? _Empty(onAdd: () => openBranchEdit(context, null))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                Text(
                  '${all.length} ta · ${all.where((b) => b.active).length} ta faol',
                  style: const TextStyle(color: AppColors.lightMuted),
                ),
                const SizedBox(height: 12),
                if (all.length > 4) ...[
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Filial nomi yoki manzil',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                for (final b in shown) ...[
                  _BranchCard(
                    branch: b,
                    isMain: b.id == mainId,
                    orders: orders.where((o) => o.branch == b.name).toList(),
                    now: now,
                    onTap: () => openBranchEdit(context, b),
                  ),
                  const SizedBox(height: 12),
                ],
                if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Hech narsa topilmadi',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.lightMuted),
                    ),
                  ),
              ],
            ),
    );
  }
}

void openBranchEdit(BuildContext context, Branch? branch) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => BranchEditScreen(branch: branch)));
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.isMain,
    required this.orders,
    required this.now,
    required this.onTap,
  });

  final Branch branch;
  final bool isMain;
  final List<Order> orders;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = branch;
    final month = orders.where((o) => Period.month.contains(o.createdAt, now));
    final monthSum = month.fold<double>(0, (a, o) => a + o.total);
    final debt = orders
        .where((o) => o.isInstalled)
        .fold<double>(0, (a, o) => a + o.remaining);
    final muted = !b.active;

    return Opacity(
      opacity: muted ? 0.6 : 1,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(
                          alpha: muted ? 0.15 : 0.35,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_icon(b.kind), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _Chip(b.kind.label),
                              if (isMain)
                                const _Chip('Asosiy', color: AppColors.accent),
                              _Chip(
                                b.active ? 'Faol' : "To'xtatilgan",
                                color: b.active ? _green : _red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.lightMuted,
                    ),
                  ],
                ),
                if (b.address.isNotEmpty ||
                    b.phone.isNotEmpty ||
                    b.manager.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  if (b.address.isNotEmpty)
                    _Line(Icons.location_on_outlined, b.address),
                  if (b.phone.isNotEmpty) _Line(Icons.phone_outlined, b.phone),
                  if (b.manager.isNotEmpty)
                    _Line(
                      Icons.badge_outlined,
                      b.hours.isEmpty ? b.manager : '${b.manager} · ${b.hours}',
                    ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _Stat('Buyurtma', '${orders.length} ta', flex: 2),
                      _Stat('Shu oy', formatMoney(monthSum), flex: 3),
                      _Stat(
                        'Qarz',
                        formatMoney(debt),
                        flex: 3,
                        color: debt > 0 ? _red : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.lightMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.lightMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.lightMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color, this.flex = 1});

  final String label;
  final String value;
  final Color? color;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.lightMuted),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

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
                color: AppColors.brand.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.store_rounded, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              "Hali filial yo'q",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              "Buyurtma kiritish uchun kamida bitta filial yoki do'kon qo'shing.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.lightMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.add_rounded),
              label: const Text("Filial qo'shish"),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filialni qo'shish yoki sozlash.
class BranchEditScreen extends StatefulWidget {
  const BranchEditScreen({super.key, this.branch});

  /// null bo'lsa yangi filial.
  final Branch? branch;

  @override
  State<BranchEditScreen> createState() => _BranchEditScreenState();
}

class _BranchEditScreenState extends State<BranchEditScreen> {
  late final Branch _b =
      widget.branch?.copy() ??
      Branch(id: 'b${DateTime.now().microsecondsSinceEpoch}', name: '');
  late final _name = TextEditingController(text: _b.name);
  late final _address = TextEditingController(text: _b.address);
  late final _phone = TextEditingController(text: _b.phone);
  late final _manager = TextEditingController(text: _b.manager);
  late final _hours = TextEditingController(text: _b.hours);
  late bool _isMain =
      widget.branch != null &&
      AppScope.read(context).mainBranch?.id == widget.branch!.id;

  bool get _isNew => widget.branch == null;

  @override
  void dispose() {
    for (final c in [_name, _address, _phone, _manager, _hours]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _problem {
    final name = _name.text.trim();
    if (name.isEmpty) return 'Nomini kiriting';
    final taken = AppScope.read(context).branches.any(
      (b) => b.id != _b.id && b.name.toLowerCase() == name.toLowerCase(),
    );
    if (taken) return 'Bu nom band';
    return null;
  }

  Future<void> _save() async {
    final state = AppScope.read(context);
    _b
      ..name = _name.text.trim()
      ..address = _address.text.trim()
      ..phone = _phone.text.trim()
      ..manager = _manager.text.trim()
      ..hours = _hours.text.trim();
    await state.saveBranch(_b);
    if (_isMain && _b.active) {
      await state.setMainBranch(_b.id);
    } else if (state.mainBranchId == _b.id) {
      await state.setMainBranch('');
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isNew ? "${_b.name} qo'shildi" : '${_b.name} saqlandi'),
      ),
    );
  }

  Future<void> _delete() async {
    final state = AppScope.read(context);
    final count = state.ordersIn(widget.branch!);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("${widget.branch!.name} o'chirilsinmi?"),
        content: Text(
          count == 0
              ? "Uni qaytarib bo'lmaydi."
              : "Bu filialda $count ta buyurtma bor. Buyurtmalar o'chmaydi, "
                    "lekin filial ro'yxatdan yo'qoladi. O'chirish o'rniga "
                    "\"Faol\"ni o'chirib qo'yish ham mumkin.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: _red),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    await state.deleteBranch(widget.branch!.id);
    messenger.showSnackBar(
      SnackBar(content: Text("${widget.branch!.name} o'chirildi")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problem;
    InputDecoration deco(String label, IconData icon, [String? hint]) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Yangi filial' : 'Filial sozlamalari'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Card(
            title: 'Turi',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in BranchKind.values)
                  ChoiceChip(
                    avatar: Icon(
                      _icon(k),
                      size: 18,
                      color: _b.kind == k ? AppColors.onBrand : null,
                    ),
                    label: Text(k.label),
                    selected: _b.kind == k,
                    showCheckmark: false,
                    selectedColor: AppColors.brand,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _b.kind == k ? AppColors.onBrand : null,
                    ),
                    onSelected: (_) => setState(() => _b.kind = k),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: "Ma'lumotlar",
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  autofocus: _isNew,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: deco(
                    'Nomi',
                    Icons.store_outlined,
                    'Masalan: №4 Olmaliq filiali',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _address,
                  decoration: deco('Manzil', Icons.location_on_outlined),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                  decoration: deco(
                    'Telefon',
                    Icons.phone_outlined,
                    '+998 90 123 45 67',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _manager,
                  textCapitalization: TextCapitalization.words,
                  decoration: deco("Mas'ul shaxs", Icons.badge_outlined),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _hours,
                  decoration: deco(
                    'Ish vaqti',
                    Icons.schedule_outlined,
                    '09:00 – 19:00',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Sozlamalar',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Faol',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "O'chirilsa, yangi buyurtmada tanlab bo'lmaydi. "
                    "Eski buyurtmalar saqlanadi.",
                  ),
                  value: _b.active,
                  onChanged: (v) => setState(() {
                    _b.active = v;
                    if (!v) _isMain = false;
                  }),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Asosiy filial',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Yangi buyurtmada avtomatik tanlanadi.'),
                  value: _isMain,
                  onChanged: _b.active
                      ? (v) => setState(() => _isMain = v)
                      : null,
                ),
              ],
            ),
          ),
          if (!_isNew) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Color(0x55E5484D)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text("Filialni o'chirish"),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: problem == null ? _save : null,
            child: Text(problem ?? (_isNew ? "Qo'shish" : 'Saqlash')),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
