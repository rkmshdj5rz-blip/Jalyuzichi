import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets/auth_layout.dart';
import 'register_screen.dart';

/// Sinov rejimidagi SMS kod. Server ulangach olib tashlanadi.
const demoSmsCode = '12345';
const _codeLength = 5;

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = 60;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _error = null));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) t.cancel();
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    if (_controller.text != demoSmsCode) {
      setState(() {
        _loading = false;
        _error = "Kod noto'g'ri. Qaytadan urinib ko'ring";
      });
      return;
    }
    setState(() => _loading = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    final mm = (_seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_seconds % 60).toString().padLeft(2, '0');

    return AuthLayout(
      title: 'Tasdiqlash',
      subtitle: '${widget.phone} raqamiga yuborilgan SMS kodni kiriting',
      buttonText: 'Davom etish',
      loading: _loading,
      onPressed: code.length == _codeLength ? _confirm : null,
      footer: const SupportTile(),
      children: [
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _codeLength; i++)
                    _CodeBox(
                      char: i < code.length ? code[i] : '',
                      active: i == code.length,
                      error: _error != null,
                    ),
                ],
              ),
              // Ko'rinmas maydon: klaviaturani ochadi va raqamlarni oladi.
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    showCursor: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_codeLength),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 20),
        Center(
          child: _seconds > 0
              ? Text(
                  '$mm:$ss dan so\'ng kodni qayta yuborish mumkin',
                  style: const TextStyle(color: AppColors.lightMuted),
                )
              : TextButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Kodni qayta yuborish'),
                ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Sinov rejimi: SMS hali ulanmagan, kod $demoSmsCode',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.char, required this.active, required this.error});

  final String char;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).inputDecorationTheme.fillColor;
    final border = error
        ? Colors.redAccent
        : active
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent;
    return Container(
      width: 54,
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Text(char,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
    );
  }
}
