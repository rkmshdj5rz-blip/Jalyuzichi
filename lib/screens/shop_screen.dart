
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/sample_orders.dart';
import '../services/brand_color.dart';
import '../widgets/logo_picker.dart';
import 'receipt_screen.dart';

/// Do'kon (brend) ma'lumotlari: nom, telefon, logo. Chek shu bo'yicha
/// bezatiladi.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final AppState _state = AppScope.read(context);
  late final _name = TextEditingController(text: _state.shopName);
  late final _phone = TextEditingController(text: _state.shopPhone);
  late Uint8List? _logo = _state.shopLogo;
  bool _logoChanged = false;
  Color? _accent;

  @override
  void initState() {
    super.initState();
    _updateAccent();
  }

  Future<void> _updateAccent() async {
    final c = await brandColorFromLogo(_logo) ??
        brandColorFromName(
            _name.text.trim().isEmpty ? 'Jalyuzichi' : _name.text.trim());
    if (mounted) setState(() => _accent = c);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _state.setShop(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      logo: _logoChanged ? _logo : null,
      removeLogo: _logoChanged && _logo == null,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Do'kon ma'lumotlari saqlandi")));
  }

  @override
  Widget build(BuildContext context) {
    final sample = sampleOrders(DateTime.now(), 1001)[1];
    return Scaffold(
      appBar: AppBar(title: const Text("Do'kon va chek")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  LogoPicker(
                    logo: _logo,
                    onChanged: (b) {
                      setState(() {
                        _logo = b;
                        _logoChanged = true;
                      });
                      _updateAccent();
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) {
                      setState(() {});
                      if (_logo == null) _updateAccent();
                    },
                    decoration: const InputDecoration(
                      labelText: "Do'kon yoki brend nomi",
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Chekdagi telefon',
                      hintText: '+998 90 123 45 67',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Chek shunday ko\'rinadi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Center(
            child: ReceiptCard(
              order: sample,
              payment: sample.payments.first,
              shopName: _name.text.trim(),
              shopPhone: _phone.text.trim(),
              logo: _logo,
              accent: _accent ?? Colors.black,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _name.text.trim().isEmpty ? null : _save,
            child: Text(_name.text.trim().isEmpty
                ? "Do'kon nomini kiriting"
                : 'Saqlash'),
          ),
        ),
      ),
    );
  }
}
