import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/orders.dart';
import '../theme.dart';

/// Yangi buyurtma kiritish: 1-qadam mahsulot va o'lchamlar,
/// 2-qadam mijoz va o'rnatish ma'lumotlari.
class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  int _step = 0;
  String _branch = branches.first;
  CustomerType? _customerType;
  final List<OrderItem> _items = [OrderItem()];

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  DateTime? _installDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    if (state.hasAddress) _address.text = '${state.region}, ${state.district}';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _area => _items.fold(0, (a, i) => a + i.area);
  int get _sizeCount => _items.fold(0, (a, i) => a + i.sizeCount);

  String? get _step1Problem {
    if (_customerType == null) return 'Buyurtmachini tanlang';
    if (_items.any((i) => i.type == null)) return 'Jalyuzi turini tanlang';
    if (_items.any((i) => i.validSizes.isEmpty)) {
      return "Har bir mahsulotga kamida bitta o'lcham kiriting";
    }
    return null;
  }

  bool get _step2Valid =>
      _customerType == CustomerType.office ||
      (_name.text.trim().isNotEmpty && _phone.text.trim().length >= 9);

  Future<void> _save() async {
    setState(() => _saving = true);
    final state = AppScope.read(context);
    final order = Order(
      number: state.nextOrderNumber,
      branch: _branch,
      customerType: _customerType!,
      items: _items,
      createdAt: DateTime.now(),
      customerName: _name.text.trim(),
      customerPhone: _phone.text.trim(),
      address: _address.text.trim(),
      note: _note.text.trim(),
      installDate: _installDate,
    );
    await state.addOrder(order);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buyurtma № ${order.number} saqlandi')),
    );
  }

  Future<void> _fromText() async {
    final sizes = await showDialog<List<OrderSize>>(
      context: context,
      builder: (_) => const _FromTextDialog(),
    );
    if (sizes == null || sizes.isEmpty) return;
    setState(() {
      final item = _items.last;
      item.sizes.removeWhere((s) => !s.isValid);
      item.sizes.addAll(sizes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final number = AppScope.of(context).nextOrderNumber;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 0);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(number: number, branch: _branch, step: _step),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: _step == 0 ? _step1() : _step2(),
                ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final problem = _step1Problem;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Jami', style: const TextStyle(color: AppColors.lightMuted)),
              const Spacer(),
              Text("$_sizeCount o'lcham · ${formatArea(_area)} m²",
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          if (_step == 0)
            FilledButton(
              onPressed: problem == null ? () => setState(() => _step = 1) : null,
              child: Text(problem ?? 'Davom etish'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = 0),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Orqaga'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _step2Valid && !_saving ? _save : null,
                    child: const Text('Buyurtmani saqlash'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _step1() {
    return [
      _Section(
        title: 'Filial',
        child: DropdownButtonFormField<String>(
          initialValue: _branch,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          decoration:
              const InputDecoration(prefixIcon: Icon(Icons.store_outlined)),
          items: [
            for (final b in branches) DropdownMenuItem(value: b, child: Text(b)),
          ],
          onChanged: (v) => setState(() => _branch = v!),
        ),
      ),
      const SizedBox(height: 12),
      _Section(
        title: 'Buyurtmachi',
        child: Row(
          children: [
            for (final t in CustomerType.values) ...[
              Expanded(
                child: _Choice(
                  label: t.label,
                  icon: t == CustomerType.office
                      ? Icons.business_rounded
                      : Icons.person_rounded,
                  selected: _customerType == t,
                  onTap: () => setState(() => _customerType = t),
                ),
              ),
              if (t != CustomerType.values.last) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          const Expanded(
            child: Text.rich(
              TextSpan(
                text: "Mahsulot va o'lchamlar ",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                    text: '(sm)',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.lightMuted),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: _fromText,
            icon: const Icon(Icons.content_paste_rounded, size: 18),
            label: const Text('Matndan'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < _items.length; i++) ...[
        _ItemCard(
          key: ObjectKey(_items[i]),
          item: _items[i],
          onChanged: () => setState(() {}),
          onRemove: _items.length > 1
              ? () => setState(() => _items.removeAt(i))
              : null,
        ),
        const SizedBox(height: 12),
      ],
      _DashedButton(
        label: "Mahsulot qo'shish",
        onTap: () => setState(() => _items.add(OrderItem())),
      ),
    ];
  }

  List<Widget> _step2() {
    return [
      if (_customerType == CustomerType.client) ...[
        _Section(
          title: 'Mijoz',
          child: Column(
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Ism familiya',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                ],
                decoration: const InputDecoration(
                  hintText: '+998 90 123 45 67',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      _Section(
        title: "O'rnatish",
        child: Column(
          children: [
            TextField(
              controller: _address,
              decoration: const InputDecoration(
                hintText: 'Manzil',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _installDate ?? now,
                  firstDate: now.subtract(const Duration(days: 1)),
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _installDate = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                child: Text(
                  _installDate == null
                      ? "O'rnatish sanasini tanlang"
                      : formatDate(_installDate!),
                  style: _installDate == null
                      ? const TextStyle(color: AppColors.lightMuted)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Izoh (rangi, materiali, boshqa istaklar)',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _Section(
        title: 'Buyurtma',
        child: Column(
          children: [
            _kv('Filial', _branch),
            _kv('Buyurtmachi', _customerType!.label),
            for (final i in _items)
              _kv(i.type ?? '',
                  "${i.sizeCount} o'lcham · ${formatArea(i.area)} m²"),
          ],
        ),
      ),
    ];
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(k,
                    style: const TextStyle(color: AppColors.lightMuted))),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.number, required this.branch, required this.step});

  final int number;
  final String branch;
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ["Mahsulot va o'lchamlar", "Mijoz va o'rnatish"];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(
                child: Text('Buyurtma',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('№ $number',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onBrand)),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Yopish',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                for (var i = 0; i < 2; i++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 5,
                      decoration: BoxDecoration(
                        color: i <= step
                            ? AppColors.brand
                            : AppColors.lightMuted.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (i == 0) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('${step + 1}/2 · ${labels[step]}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightMuted)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

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
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).inputDecorationTheme.fillColor;
    return Material(
      color: selected ? AppColors.brand : fill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20, color: selected ? AppColors.onBrand : null),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.onBrand : null)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.onChanged,
    this.onRemove,
  });

  final OrderItem item;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: item.type,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14),
                    decoration: const InputDecoration(
                      hintText: 'Jalyuzi turi',
                      prefixIcon: Icon(Icons.blinds_outlined),
                    ),
                    items: [
                      for (final t in productTypes)
                        DropdownMenuItem(value: t, child: Text(t)),
                    ],
                    onChanged: (v) {
                      item.type = v;
                      onChanged();
                    },
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: "Mahsulotni o'chirish",
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < item.sizes.length; i++)
              _SizeRow(
                key: ObjectKey(item.sizes[i]),
                size: item.sizes[i],
                onChanged: onChanged,
                onRemove: item.sizes.length > 1
                    ? () {
                        item.sizes.removeAt(i);
                        onChanged();
                      }
                    : null,
              ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    item.sizes.add(OrderSize());
                    onChanged();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("O'lcham"),
                ),
                Expanded(
                  child: Text(
                      "${item.sizeCount} o'lcham · ${formatArea(item.area)} m²",
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.lightMuted)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  const _SizeRow({
    super.key,
    required this.size,
    required this.onChanged,
    this.onRemove,
  });

  final OrderSize size;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  static String _initial(num v) => v == 0 ? '' : formatArea(v.toDouble());

  @override
  Widget build(BuildContext context) {
    double parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;
    final numberInput = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
    ];
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        );
    const sep = TextStyle(fontSize: 16, color: AppColors.lightMuted);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: _initial(size.width),
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: numberInput,
              decoration: deco('eni'),
              onChanged: (v) {
                size.width = parse(v);
                onChanged();
              },
            ),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('×', style: sep)),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: _initial(size.height),
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: numberInput,
              decoration: deco("bo'yi"),
              onChanged: (v) {
                size.height = parse(v);
                onChanged();
              },
            ),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('=', style: sep)),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: '${size.count}',
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: deco('soni'),
              onChanged: (v) {
                size.count = int.tryParse(v) ?? 0;
                onChanged();
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: onRemove == null
                ? null
                : IconButton(
                    tooltip: "O'lchamni o'chirish",
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: BorderSide(
            color: AppColors.lightMuted.withValues(alpha: 0.5), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      icon: const Icon(Icons.add_rounded),
      label: Text(label),
    );
  }
}

/// O'lchamlarni matndan (masalan Telegram xabaridan) qo'shish oynasi.
class _FromTextDialog extends StatefulWidget {
  const _FromTextDialog();

  @override
  State<_FromTextDialog> createState() => _FromTextDialogState();
}

class _FromTextDialogState extends State<_FromTextDialog> {
  final _controller = TextEditingController();
  List<OrderSize> _found = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Matndan o'lcham qo'shish"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Har bir qatorga eni x bo'yi va soni yozing, masalan:\n120x150\n80x200 2",
            style: TextStyle(color: AppColors.lightMuted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            onChanged: (v) => setState(() => _found = parseSizes(v)),
            decoration: const InputDecoration(hintText: '120x150'),
          ),
          const SizedBox(height: 8),
          Text("Topildi: ${_found.length} ta o'lcham",
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bekor qilish'),
        ),
        TextButton(
          onPressed:
              _found.isEmpty ? null : () => Navigator.of(context).pop(_found),
          child: const Text("Qo'shish"),
        ),
      ],
    );
  }
}
