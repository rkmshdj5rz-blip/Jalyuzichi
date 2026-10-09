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
      {Widget? avatar, Key? key}) {
    return ChoiceChip(
      key: key,
      label: Text(label),
      avatar: avatar,
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

  static const _karnizColors = {
    'Oq': Color(0xFFFFFFFF),
    'Kumush': Color(0xFFC0C4CC),
    'Jigarrang': Color(0xFF7B4A2A),
    'Qora': Color(0xFF1C1C1C),
    'Oltin': Color(0xFFD4A84B),
  };

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
            for (final k in karnizOptions)
              _chip(
                k,
                _o.karniz == k,
                () => _o.karniz = k,
                key: ValueKey('karniz-$k'),
                avatar: _karnizColors[k] == null
                    ? null
                    : Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _karnizColors[k],
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.lightMuted
                                  .withValues(alpha: 0.5)),
                        ),
                      ),
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
