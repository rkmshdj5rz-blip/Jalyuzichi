import 'package:flutter/material.dart';

import '../data/orders.dart';
import '../theme.dart';

/// Natija: tanlangan sozlamalar va "hammasiga" qo'llash kerakmi.
class SizeOptionsResult {
  const SizeOptionsResult(this.options, {this.applyToAll = false});
  final OrderSize options;
  final bool applyToAll;
}

/// O'lcham sozlamalari: boshqaruv, tomon, karniz.
Future<SizeOptionsResult?> showSizeOptions(
  BuildContext context, {
  required int index,
  required OrderSize size,
  bool canApplyToAll = false,
}) {
  return showModalBottomSheet<SizeOptionsResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _OptionsSheet(
        index: index, size: size, canApplyToAll: canApplyToAll),
  );
}

class _OptionsSheet extends StatefulWidget {
  const _OptionsSheet(
      {required this.index, required this.size, required this.canApplyToAll});

  final int index;
  final OrderSize size;
  final bool canApplyToAll;

  @override
  State<_OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<_OptionsSheet> {
  late final OrderSize _o = OrderSize()..copyOptionsFrom(widget.size);

  Widget _group(String title, List<Widget> chips) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightMuted)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback? onTap,
      {Key? key}) {
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: onTap == null ? null : (_) => setState(onTap),
      selectedColor: AppColors.brand,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.onBrand : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noControl = _o.control == Control.none;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("${widget.index + 1}-o'lcham sozlamalari",
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _group('Boshqaruv', [
            for (final c in Control.values)
              _chip(c.label, _o.control == c, () => _o.control = c,
                  key: ValueKey('ctl-${c.name}')),
          ]),
          _group('Tomon', [
            for (final s in Side.values)
              _chip(s.label, !noControl && _o.side == s,
                  noControl ? null : () => _o.side = s,
                  key: ValueKey('side-${s.name}')),
          ]),
          _group('Karniz', [
            _KarnizField(
              key: const ValueKey('karniz-field'),
              value: _o.karniz,
              onTap: () async {
                final k = await showKarnizPicker(context, selected: _o.karniz);
                if (k != null) setState(() => _o.karniz = k);
              },
            ),
          ]),
          const SizedBox(height: 4),
          Row(
            children: [
              if (widget.canApplyToAll) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context)
                        .pop(SizeOptionsResult(_o, applyToAll: true)),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: const Text('Hammasiga'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(SizeOptionsResult(_o)),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Tayyor'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rang namunasi (karnizsiz uchun chizilgan katak).
class KarnizSwatch extends StatelessWidget {
  const KarnizSwatch({super.key, required this.name, this.size = 18});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = findKarniz(name)?.color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c == null ? null : Color(c),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.lightMuted.withValues(alpha: 0.6)),
      ),
      child: c == null
          ? Icon(Icons.block_rounded,
              size: size - 4, color: AppColors.lightMuted)
          : null,
    );
  }
}

class _KarnizField extends StatelessWidget {
  const _KarnizField({super.key, required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: dark ? AppColors.darkSurface : AppColors.lightBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                KarnizSwatch(name: value, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const Text('Tanlash',
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w600)),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Karniz turi va rangini tanlash (to'r ko'rinishida).
Future<String?> showKarnizPicker(BuildContext context,
    {required String selected}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      return ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Karniz turi va rangi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 130,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.05,
                ),
                itemCount: karnizOptions.length,
                itemBuilder: (_, i) {
                  final k = karnizOptions[i];
                  final sel = k.name == selected;
                  return Material(
                    key: ValueKey('karniz-${k.name}'),
                    color: sel
                        ? AppColors.brand
                        : (dark ? AppColors.darkSurface : AppColors.lightBg),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(context).pop(k.name),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            KarnizSwatch(name: k.name, size: 26),
                            const SizedBox(height: 8),
                            Text(
                              k.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: sel ? AppColors.onBrand : null,
                              ),
                            ),
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
      );
    },
  );
}
