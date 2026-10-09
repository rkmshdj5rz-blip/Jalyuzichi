import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/auth_layout.dart';
import '../widgets/logo_picker.dart';
import 'sync_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _controller = TextEditingController();
  final _shop = TextEditingController();
  Uint8List? _logo;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _shop.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _shop.dispose();
    super.dispose();
  }

  bool get _valid =>
      _controller.text.trim().length >= 2 && _shop.text.trim().length >= 2;

  Future<void> _register() async {
    final state = AppScope.read(context);
    await state.setShop(
      name: _shop.text.trim(),
      phone: state.shopPhone,
      logo: _logo,
    );
    await state.register(_controller.text.trim());
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SyncScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: "Ro'yxatdan o'tish",
      subtitle:
          "Ismingiz va do'koningiz nomini kiriting. Nom va logo cheklarda chiqadi.",
      buttonText: "Ro'yxatdan o'tish",
      onPressed: _valid ? _register : null,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Ismingiz',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _shop,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: "Do'kon yoki brend nomi",
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
        ),
        const SizedBox(height: 16),
        LogoPicker(
          logo: _logo,
          onChanged: (b) => setState(() => _logo = b),
        ),
      ],
    );
  }
}
