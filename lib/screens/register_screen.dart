import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/auth_layout.dart';
import 'sync_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    await AppScope.read(context).register(_controller.text.trim());
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
      subtitle: "Ro'yxatdan o'tish uchun ismingizni kiriting",
      buttonText: "Ro'yxatdan o'tish",
      onPressed: _controller.text.trim().length >= 2 ? _register : null,
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
      ],
    );
  }
}
