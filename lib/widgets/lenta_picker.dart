import 'package:flutter/material.dart';

import '../data/orders.dart';
import '../data/products.dart';
import '../theme.dart';

/// Lenta kodini qidirib tanlash oynasi. Tanlangan mahsulotni qaytaradi.
Future<Product?> showLentaPicker(
  BuildContext context, {
  required String type,
  required List<Product> products,
  String selected = '',
}) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _LentaSheet(type: type, products: products, selected: selected),
  );
}

class _LentaSheet extends StatefulWidget {
  const _LentaSheet(
      {required this.type, required this.products, required this.selected});

  final String type;
  final List<Product> products;
  final String selected;

  @override
  State<_LentaSheet> createState() => _LentaSheetState();
}

class _LentaSheetState extends State<_LentaSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = [
      for (final p in widget.products)
        if (q.isEmpty || p.collection.toLowerCase().contains(q)) p
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: widget.type,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                        children: const [
                          TextSpan(
                            text: '  lenta kodi',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.lightMuted),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Yopish',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: widget.products.length > 8,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Kodni yozing: L-101, 7002...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Text('${list.length} ta kod',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.lightMuted)),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          "Bunday kod yo'q. Narxlar bo'limida qo'shing.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.lightMuted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final p = list[i];
                        final sel = p.collection == widget.selected;
                        return Material(
                          color: sel
                              ? AppColors.brand
                              : (dark
                                  ? AppColors.darkSurface
                                  : AppColors.lightBg),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context).pop(p),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 15),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.collection.isEmpty
                                          ? '—'
                                          : p.collection,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            sel ? AppColors.onBrand : null,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${formatMoney(p.price)} / m²',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? AppColors.onBrand
                                          : AppColors.accent,
                                    ),
                                  ),
                                  if (sel) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle_rounded,
                                        size: 20, color: AppColors.onBrand),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
