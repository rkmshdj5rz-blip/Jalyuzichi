import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/countries.dart';
import '../services/auth_service.dart';
import '../widgets/auth_layout.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key, required this.country});

  final Country country;

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  String get _digits => _controller.text.replaceAll(' ', '');
  bool get _valid => _digits.length == widget.country.digits;

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

  Future<void> _continue() async {
    setState(() => _loading = true);
    final phone = '${widget.country.code}$_digits';
    await AppScope.read(context).setPhone(phone);
    await authService.sendCode(phone, CodeChannel.telegram);
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(phone: phone, channel: CodeChannel.telegram),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Xush kelibsiz',
      subtitle: "Telefon raqamingizni kiriting, tasdiqlash kodini Telegram'ingizga yuboramiz",
      buttonText: 'Davom etish',
      loading: _loading,
      onPressed: _valid ? _continue : null,
      footer: const SupportTile(),
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.country.digits),
            _PhoneFormatter(),
          ],
          decoration: InputDecoration(
            hintText: widget.country.digits == 9 ? '90 123 45 67' : null,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Text(
                '${widget.country.flag}  ${widget.country.code}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
          ),
        ),
      ],
    );
  }
}

/// Raqamni "90 123 45 67" ko'rinishida guruhlaydi.
class _PhoneFormatter extends TextInputFormatter {
  static const _groups = [2, 3, 2, 2, 2];

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    var i = 0;
    for (final g in _groups) {
      if (i >= digits.length) break;
      if (buf.isNotEmpty) buf.write(' ');
      final end = (i + g).clamp(0, digits.length);
      buf.write(digits.substring(i, end));
      i = end;
    }
    if (i < digits.length) buf.write(digits.substring(i));
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
