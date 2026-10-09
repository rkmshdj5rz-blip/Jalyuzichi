import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/orders.dart';
import '../data/products.dart';
import '../theme.dart';
import '../widgets/money_field.dart';

/// Yangi buyurtma kiritish: 1-qadam mahsulot va o'lchamlar,
/// 2-qadam mijoz, o'rnatish va to'lov ma'lumotlari.
/// [editing] berilsa, mavjud buyurtma tahrirlanadi.
class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key, this.editing});

  final Order? editing;

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  int _step = 0;
  String _branch = '';
  CustomerType? _customerType;
  final List<OrderItem> _items = [OrderItem()];

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  final _discount = TextEditingController();

  /// Chegirma foizda (true) yoki so'mda (false) kiritiladi.
  bool _discountPercent = true;
  final _prepay = TextEditingController();
  DateTime? _installDate;
  bool _saving = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _branch = e.branch;
      _customerType = e.customerType;
      _items
        ..clear()
        ..addAll([for (final i in e.items) OrderItem.fromJson(i.toJson())]);
      _name.text = e.customerName;
      _phone.text = e.customerPhone;
      _address.text = e.address;
      _note.text = e.note;
      _installDate = e.installDate;
      // Saqlangan chegirma so'mda, tahrirda ham so'mda ko'rsatamiz.
      _discountPercent = e.discount == 0;
      _discount.text = MoneyField.text(e.discount);
      return;
    }
    final state = AppScope.read(context);
    _branch = state.mainBranch?.name ?? '';
    if (state.hasAddress) _address.text = '${state.region}, ${state.district}';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    _discount.dispose();
    _prepay.dispose();
    super.dispose();
  }

  double get _area => _items.fold(0, (a, i) => a + i.area);
  int get _sizeCount => _items.fold(0, (a, i) => a + i.sizeCount);
  double get _itemsSum => _items.fold(0, (a, i) => a + i.sum);
  double get _discountInput =>
      double.tryParse(_discount.text.replaceAll(' ', '').replaceAll(',', '.')) ??
      0;

  /// Chegirma so'mda (foiz bo'lsa mahsulotlar summasidan hisoblanadi).
  double get _discountValue => _discountPercent
      ? (_itemsSum * _discountInput / 100).roundToDouble()
      : parseMoney(_discount.text);
  double get _prepayValue => parseMoney(_prepay.text);
  double get _total =>
      (_itemsSum - _discountValue).clamp(0, double.infinity).toDouble();

  String? get _step1Problem {
    if (_branch.isEmpty) return 'Filialni tanlang';
    if (_customerType == null) return 'Buyurtmachini tanlang';
    if (_items.any((i) => i.type == null)) return 'Jalyuzi turini tanlang';
    if (_items.any((i) => i.validSizes.isEmpty)) {
      return "Har bir mahsulotga kamida bitta o'lcham kiriting";
    }
    return null;
  }

  String? get _step2Problem {
    if (_customerType == CustomerType.client) {
      if (_name.text.trim().isEmpty) return 'Mijoz ismini kiriting';
      if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 9) {
        return 'Telefon raqamni kiriting';
      }
    }
    if (_discountPercent && _discountInput > 100) {
      return "Chegirma 100% dan ko'p bo'lmaydi";
    }
    if (_discountValue > _itemsSum) return "Chegirma summadan ko'p";
    if (_prepayValue > _total) return "Oldindan to'lov summadan ko'p";
    return null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final state = AppScope.read(context);
    final e = widget.editing;
    final now = DateTime.now();
    final order = Order(
      number: e?.number ?? state.nextOrderNumber,
      branch: _branch,
      customerType: _customerType!,
      items: _items,
      createdAt: e?.createdAt ?? now,
      customerName: _name.text.trim(),
      customerPhone: _phone.text.trim(),
      address: _address.text.trim(),
      note: _note.text.trim(),
      installDate: _installDate,
      discount: _discountValue,
      payments: e?.payments ??
          [if (_prepayValue > 0) Payment(amount: _prepayValue, date: now)],
      installedAt: e?.installedAt,
    );
    if (e != null) {
      await state.updateOrder(order);
    } else {
      await state.addOrder(order);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(e != null
              ? "Buyurtma № ${order.number} o'zgartirildi"
              : 'Buyurtma № ${order.number} saqlandi')),
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
    final number =
        widget.editing?.number ?? AppScope.of(context).nextOrderNumber;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 0);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                  number: number,
                  title: _isEdit ? 'Tahrirlash' : 'Buyurtma',
                  step: _step),
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
    final problem = _step == 0 ? _step1Problem : _step2Problem;
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
              Expanded(
                child: Text("$_sizeCount dona · ${formatArea(_area)} m²",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.lightMuted)),
              ),
              Text(formatMoney(_step == 0 ? _itemsSum : _total),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
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
                    onPressed: problem == null && !_saving ? _save : null,
                    child: Text(problem ??
                        (_isEdit ? 'Saqlash' : 'Buyurtmani saqlash')),
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
          initialValue: _branch.isEmpty ? null : _branch,
          hint: const Text("Filial yo'q: Filiallar bo'limida qo'shing"),
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          decoration:
              const InputDecoration(prefixIcon: Icon(Icons.store_outlined)),
          items: [
            for (final b in {
              for (final b in AppScope.read(context).activeBranches) b.name,
              if (_branch.isNotEmpty) _branch,
            })
              DropdownMenuItem(value: b, child: Text(b)),
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
          products: AppScope.read(context).products,
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
        title: "To'lov",
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _discountPercent
                      ? TextField(
                          controller: _discount,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d{0,3}([.,]\d{0,2})?')),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Chegirma',
                            prefixIcon: Icon(Icons.discount_outlined),
                            suffixText: '%',
                          ),
                        )
                      : MoneyField(
                          controller: _discount,
                          label: 'Chegirma',
                          icon: Icons.discount_outlined,
                          onChanged: (_) => setState(() {}),
                        ),
                ),
                const SizedBox(width: 10),
                _UnitSwitch(
                  percent: _discountPercent,
                  onChanged: (v) => setState(() {
                    _discountPercent = v;
                    _discount.clear();
                  }),
                ),
              ],
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 10),
              MoneyField(
                controller: _prepay,
                label: "Oldindan to'lov (zaklad)",
                icon: Icons.payments_outlined,
                onChanged: (_) => setState(() {}),
              ),
            ],
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
              _kv(i.model.isEmpty ? i.type ?? '' : '${i.type} · ${i.model}',
                  "${i.sizeCount} dona · ${formatArea(i.area)} m²"),
            const Divider(height: 20),
            _kv('Mahsulotlar', formatMoney(_itemsSum)),
            if (_discountValue > 0)
              _kv(
                  _discountPercent
                      ? 'Chegirma (${_discount.text.trim()}%)'
                      : 'Chegirma',
                  '− ${formatMoney(_discountValue)}'),
            _kv('Umumiy summa', formatMoney(_total), bold: true),
            if (!_isEdit && _prepayValue > 0) ...[
              _kv("Oldindan to'lov", formatMoney(_prepayValue)),
              _kv('Qoldiq', formatMoney(_total - _prepayValue), bold: true),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _kv(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(k,
                    overflow: TextOverflow.ellipsis,
                    style: bold
                        ? const TextStyle(fontWeight: FontWeight.w700)
                        : const TextStyle(color: AppColors.lightMuted))),
            const SizedBox(width: 8),
            Text(v,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    fontSize: bold ? 16 : null)),
          ],
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.number, required this.title, required this.step});

  final int number;
  final String title;
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ["Mahsulot va o'lchamlar", "Mijoz, o'rnatish va to'lov"];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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

class _ItemCard extends StatefulWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.products,
    required this.onChanged,
    this.onRemove,
  });

  final OrderItem item;
  final List<Product> products;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final _price =
      TextEditingController(text: MoneyField.text(widget.item.pricePerM2));

  OrderItem get item => widget.item;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  List<Product> _ofType(String? type) =>
      [for (final p in widget.products) if (p.type == type) p];

  void _setPrice(double v) {
    item.pricePerM2 = v;
    _price.text = MoneyField.text(v);
  }

  void _setType(String? type) {
    if (type == item.type) return;
    item.type = type;
    // Turda bitta collection bo'lsa, o'zi tanlanadi.
    final list = _ofType(type);
    if (list.length == 1) {
      item.model = list.single.collection;
      _setPrice(list.single.price);
    } else {
      item.model = '';
      _setPrice(0);
    }
    widget.onChanged();
  }

  void _setCollection(String? c) {
    final p = _ofType(item.type).where((p) => p.collection == c).firstOrNull;
    item.model = c ?? '';
    if (p != null) _setPrice(p.price);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = widget.onChanged;
    final types = {...typesOf(widget.products), ?item.type}.toList();
    final collections = {
      for (final p in _ofType(item.type)) p.collection,
      if (item.model.isNotEmpty) item.model,
    }.toList();
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
                    decoration: InputDecoration(
                      hintText: types.isEmpty
                          ? "Avval Narxlarda mahsulot qo'shing"
                          : 'Jalyuzi turi',
                      prefixIcon: const Icon(Icons.blinds_outlined),
                    ),
                    items: [
                      for (final t in types)
                        DropdownMenuItem(value: t, child: Text(t)),
                    ],
                    onChanged: _setType,
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    tooltip: "Mahsulotni o'chirish",
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('c-${item.type}'),
                    initialValue: item.model.isEmpty ? null : item.model,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14),
                    decoration: const InputDecoration(
                      hintText: 'Collection',
                      prefixIcon: Icon(Icons.layers_outlined),
                    ),
                    items: [
                      for (final c in collections)
                        DropdownMenuItem(
                            value: c, child: Text(c.isEmpty ? '—' : c)),
                    ],
                    onChanged: item.type == null ? null : _setCollection,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  child: MoneyField(
                    controller: _price,
                    label: '1 m² narxi',
                    icon: Icons.sell_outlined,
                    suffix: "so'm",
                    onChanged: (v) {
                      item.pricePerM2 = v;
                      onChanged();
                    },
                  ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          "${item.sizeCount} dona · ${formatArea(item.area)} m²",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.lightMuted)),
                      Text(formatMoney(item.sum),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
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

/// Chegirma birligi: % yoki so'm.
class _UnitSwitch extends StatelessWidget {
  const _UnitSwitch({required this.percent, required this.onChanged});

  final bool percent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).inputDecorationTheme.fillColor;
    Widget seg(String label, bool value) {
      final on = percent == value;
      return GestureDetector(
        key: ValueKey('discount-${value ? 'percent' : 'sum'}'),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: on ? AppColors.onBrand : AppColors.lightMuted)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg('%', true), seg("so'm", false)],
      ),
    );
  }
}
