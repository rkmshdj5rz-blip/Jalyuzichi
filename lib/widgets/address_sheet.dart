import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/regions.dart';
import '../screens/map_screen.dart';

/// "Manzil kiritish" oynasini ochadi.
Future<void> showAddressSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => const _AddressSheet(),
  );
}

class _AddressSheet extends StatefulWidget {
  const _AddressSheet();

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  String? _region;
  String? _district;
  bool _pickedOnMap = false;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    if (state.hasAddress) {
      _region = state.region;
      _district = state.district;
    }
  }

  Future<void> _openMap() async {
    final picked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
    if (picked == true) setState(() => _pickedOnMap = true);
  }

  Future<void> _save() async {
    await AppScope.read(context).setAddress(_region!, _district!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final districts = _region == null ? const <String>[] : uzRegions[_region]!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Manzil kiritish',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _region,
            isExpanded: true,
            borderRadius: BorderRadius.circular(14),
            decoration: const InputDecoration(
              hintText: 'Viloyat',
              prefixIcon: Icon(Icons.map_outlined),
            ),
            items: [
              for (final r in uzRegions.keys)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: (v) => setState(() {
              _region = v;
              _district = null;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_region),
            initialValue: _district,
            isExpanded: true,
            borderRadius: BorderRadius.circular(14),
            decoration: const InputDecoration(
              hintText: 'Tuman yoki shahar',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            items: [
              for (final d in districts)
                DropdownMenuItem(value: d, child: Text(d)),
            ],
            onChanged: _region == null
                ? null
                : (v) => setState(() => _district = v),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openMap,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: Icon(_pickedOnMap
                ? Icons.check_circle_rounded
                : Icons.location_on_outlined),
            label: Text(_pickedOnMap
                ? 'Xaritada belgilandi'
                : 'Xaritadan manzilni belgilash'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Yopish'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed:
                      _region != null && _district != null ? _save : null,
                  child: const Text('Saqlash'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
