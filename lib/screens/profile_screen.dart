import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/auth_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _controller =
      TextEditingController(text: AppScope.read(context).name);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return AuthLayout(
      title: 'Profilni tahrirlash',
      buttonText: 'Saqlash',
      onPressed: () async {
        final name = _controller.text.trim();
        if (name.length >= 2) await state.register(name);
        if (context.mounted) Navigator.of(context).pop();
      },
      children: [
        TextField(
          controller: _controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Ism',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          enabled: false,
          initialValue: state.phone,
          decoration: const InputDecoration(
            labelText: 'Telefon raqam',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
      ],
    );
  }
}
