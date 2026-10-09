import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/orders.dart';
import '../data/products.dart';
import '../theme.dart';
import '../widgets/money_field.dart';

const _red = Color(0xFFE5484D);

/// Narxlar: mahsulot qo'shish (tur, collection, 1 m² narxi) va katalog.
/// Yangi buyurtmada narx shu yerdan avtomatik qo'yiladi.
class PricesScreen extends StatelessWidget {
  const PricesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final products = state.products;
    final types = typesOf(products);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('Narxlar',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          const Text(
              "1 m² uchun. Yangi buyurtmada narx shu yerdan o'zi qo'yiladi.",
              style: TextStyle(color: AppColors.lightMuted)),
          const SizedBox(height: 16),
          _AddProduct(types: types),
          const SizedBox(height: 20),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text("Hali mahsulot yo'q. Yuqorida birinchisini qo'shing.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.lightMuted)),
            ),
          for (final t in types) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  Text('${products.where((p) => p.type == t).length} ta',
                      style: const TextStyle(color: AppColors.lightMuted)),
                ],
              ),
            ),
            Card(
              child: Column(
                children: [
                  for (final p in products.where((p) => p.type == t)) ...[
                    if (p != products.firstWhere((x) => x.type == t))
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
                      title: Text(p.collection.isEmpty ? '—' : p.collection,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${formatMoney(p.price)} / m²'),
                      trailing: const Icon(Icons.edit_outlined, size: 20),
                      onTap: () => _edit(context, p),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, Product p) async {
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<Object>(
      context: context,
      builder: (_) => _EditDialog(product: p),
    );
    if (result == 'delete') {
      await state.deleteProduct(p.id);
      messenger.showSnackBar(
          SnackBar(content: Text("${p.label} o'chirildi")));
    } else if (result is Product) {
      await state.saveProduct(result);
    }
  }
}

/// Limon kartadagi "Mahsulot qo'shish" formasi.
class _AddProduct extends StatefulWidget {
  const _AddProduct({required this.types});

  final List<String> types;

  @override
  State<_AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<_AddProduct> {
  final _type = TextEditingController();
  final _collection = TextEditingController();
  final _price = TextEditingController();

  @override
  void dispose() {
    _type.dispose();
    _collection.dispose();
    _price.dispose();
    super.dispose();
  }

  String? get _problem {
    if (_type.text.trim().isEmpty) return 'Jalyuzi turini yozing';
    if (_collection.text.trim().isEmpty) return 'Collectionni yozing';
    if (parseMoney(_price.text) <= 0) return 'Narxini yozing';
    return null;
  }

  Future<void> _add() async {
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    // Tur avvaldan bor bo'lsa, uning yozilishini saqlaymiz.
    final typed = _type.text.trim();
    final type = widget.types
            .where((t) => t.toLowerCase() == typed.toLowerCase())
            .firstOrNull ??
        typed;
    final collection = _collection.text.trim();
    final price = parseMoney(_price.text);
    final existing = state.findProduct(type, collection);
    if (existing != null) {
      await state.saveProduct(existing..price = price);
      messenger.showSnackBar(SnackBar(
          content: Text('${existing.label}: narx yangilandi')));
    } else {
      final p = Product(
        id: 'p${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        collection: collection,
        price: price,
      );
      await state.saveProduct(p);
      messenger.showSnackBar(
          SnackBar(content: Text("${p.label} qo'shildi")));
    }
    // Tur qoladi: bir turga bir nechta collection ketma-ket qo'shiladi.
    _collection.clear();
    _price.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problem;
    final base = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Theme(
        // Limon fonda maydonlar oq bo'ladi.
        data: base.copyWith(
          inputDecorationTheme: base.inputDecorationTheme.copyWith(
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: AppColors.lightMuted),
            labelStyle: const TextStyle(color: AppColors.lightMuted),
            floatingLabelStyle: const TextStyle(color: AppColors.onBrand),
            prefixIconColor: AppColors.onBrand,
            suffixStyle: const TextStyle(color: AppColors.lightMuted),
          ),
          textSelectionTheme: const TextSelectionThemeData(
              cursorColor: AppColors.onBrand),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.add_box_outlined, color: AppColors.onBrand),
                SizedBox(width: 8),
                Text("Mahsulot qo'shish",
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onBrand)),
              ],
            ),
            const SizedBox(height: 12),
            _field(_type, 'Jalyuzi turi', 'Masalan: Kombo',
                Icons.blinds_outlined),
            if (widget.types.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final t in widget.types)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _TypeChip(
                          label: t,
                          selected: _type.text.trim().toLowerCase() ==
                              t.toLowerCase(),
                          onTap: () => setState(() => _type.text = t),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            _field(_collection, 'Collection', 'Masalan: Collection-1',
                Icons.layers_outlined),
            const SizedBox(height: 10),
            MoneyField(
              controller: _price,
              label: '1 m² narxi',
              icon: Icons.sell_outlined,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: problem == null ? _add : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.onBrand,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.onBrand.withValues(alpha: 0.15),
                disabledForegroundColor:
                    AppColors.onBrand.withValues(alpha: 0.6),
              ),
              icon: Icon(problem == null ? Icons.add_rounded : null),
              label: Text(problem ?? "Qo'shish"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint,
      IconData icon) {
    return TextField(
      controller: c,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(color: AppColors.onBrand),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.onBrand
          : AppColors.onBrand.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.onBrand)),
        ),
      ),
    );
  }
}

/// Mahsulotni o'zgartirish yoki o'chirish oynasi.
/// Natija: o'zgargan [Product] yoki 'delete'.
class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.product});

  final Product product;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _type = TextEditingController(text: widget.product.type);
  late final _collection =
      TextEditingController(text: widget.product.collection);
  late final _price =
      TextEditingController(text: MoneyField.text(widget.product.price));

  @override
  void dispose() {
    _type.dispose();
    _collection.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _type.text.trim().isNotEmpty && parseMoney(_price.text) > 0;
    return AlertDialog(
      title: const Text('Mahsulot'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _type,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Jalyuzi turi'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _collection,
              decoration: const InputDecoration(labelText: 'Collection'),
            ),
            const SizedBox(height: 10),
            MoneyField(
              controller: _price,
              label: '1 m² narxi',
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text("${widget.product.label} o'chirilsinmi?"),
                content: const Text(
                    "Eski buyurtmalardagi narxlar o'zgarmaydi."),
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
            if (ok == true && context.mounted) {
              Navigator.of(context).pop('delete');
            }
          },
          style: TextButton.styleFrom(foregroundColor: _red),
          child: const Text("O'chirish"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: valid
              ? () => Navigator.of(context).pop(Product(
                    id: widget.product.id,
                    type: _type.text.trim(),
                    collection: _collection.text.trim(),
                    price: parseMoney(_price.text),
                  ))
              : null,
          child: const Text('Saqlash'),
        ),
      ],
    );
  }
}
