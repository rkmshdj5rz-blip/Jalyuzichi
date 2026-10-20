import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../data/orders.dart';
import '../services/brand_color.dart';
import '../services/file_saver.dart';
import '../theme.dart';
import 'shop_screen.dart';

/// To'lov (avans) cheki: ko'rish, rasm qilib saqlash, Telegramga yuborish.
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.number, required this.payment});

  final int number;
  final Payment payment;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _boundary = GlobalKey();
  Color? _accent;
  Uint8List? _logoFor;
  bool _busy = false;

  Future<void> _loadAccent(AppState state) async {
    final logo = state.shopLogo;
    if (identical(logo, _logoFor) && _accent != null) return;
    _logoFor = logo;
    final c = await brandColorFromLogo(logo) ??
        brandColorFromName(state.shopName.isEmpty ? 'Jalyuzichi' : state.shopName);
    if (mounted) setState(() => _accent = c);
  }

  Future<Uint8List?> _png() async {
    final r = _boundary.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (r == null) return null;
    final image = await r.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  String get _fileName => 'chek-${widget.number}';

  Future<void> _save() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final png = await _png();
    final ok = png != null && await saveImage(png, _fileName);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(
        content: Text(ok ? 'Chek saqlandi' : "Chekni saqlab bo'lmadi")));
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final png = await _png();
    if (png == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    var shared = false;
    try {
      final r = await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png', name: '$_fileName.png')],
        fileNameOverrides: ['$_fileName.png'],
        text: 'Buyurtma № ${widget.number} cheki',
      ));
      shared = r.status != ShareResultStatus.unavailable;
    } catch (_) {
      shared = false;
    }
    if (!shared) {
      // Ulashish ishlamasa (masalan brauzerda), rasm yuklab olinadi.
      final ok = await saveImage(png, _fileName);
      messenger.showSnackBar(SnackBar(
          content: Text(ok
              ? "Chek yuklab olindi. Telegramda rasm sifatida yuboring."
              : "Chekni yuborib bo'lmadi")));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _loadAccent(state);
    final order =
        state.orders.where((o) => o.number == widget.number).firstOrNull;
    if (order == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Buyurtma topilmadi')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chek'),
        leading: IconButton(
          tooltip: 'Yopish',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShopScreen())),
            child: const Text('Dizayn'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (state.shopName.isEmpty) ...[
            _Hint(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ShopScreen())),
            ),
            const SizedBox(height: 12),
          ],
          Center(
            child: RepaintBoundary(
              key: _boundary,
              child: ReceiptCard(
                order: order,
                payment: widget.payment,
                shopName: state.shopName,
                shopPhone: state.shopPhone,
                logo: state.shopLogo,
                accent: _accent ?? AppColors.onBrand,
                branchPhone: state.branches
                        .where((b) => b.name == order.branch)
                        .firstOrNull
                        ?.phone ??
                    '',
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _save,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Saqlash'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _share,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF229ED9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Telegramga yuborish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.storefront_rounded),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                    "Chekda do'koningiz nomi va logosi chiqishi uchun ularni kiriting",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chekning o'zi. Har doim oq fonda (rasm qilib yuborish uchun).
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    super.key,
    required this.order,
    required this.payment,
    required this.shopName,
    required this.shopPhone,
    required this.logo,
    required this.accent,
    this.branchPhone = '',
  });

  final Order order;
  final Payment payment;
  final String shopName;
  final String shopPhone;
  final Uint8List? logo;
  final Color accent;
  final String branchPhone;

  static const _ink = Color(0xFF15171E);
  static const _muted = Color(0xFF7A7A88);

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium!.copyWith(color: _ink);
    final name = shopName.isEmpty ? 'Jalyuzichi' : shopName;
    final onAccent =
        accent.computeLuminance() > 0.5 ? _ink : Colors.white;
    // Shu to'lovgacha (shu jumladan) to'langan summa.
    final idx = order.payments.indexOf(payment);
    final paidSoFar = order.payments
        .take(idx < 0 ? order.payments.length : idx + 1)
        .fold<double>(0, (a, p) => a + p.amount);
    final left = (order.total - paidSoFar).clamp(0, double.infinity).toDouble();
    final isAdvance = idx <= 0 && left > 0;
    final itemsSum = order.items.fold<double>(0, (a, i) => a + i.sum);
    final phone = branchPhone.isNotEmpty ? branchPhone : shopPhone;
    final d = payment.date;
    final time =
        '${formatDate(d)}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    Widget row(String k, String v,
            {bool bold = false, Color? color, double size = 14}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(k,
                    style: base.copyWith(
                        fontSize: size,
                        color: bold ? _ink : _muted,
                        fontWeight: bold ? FontWeight.w700 : null)),
              ),
              const SizedBox(width: 12),
              Text(v,
                  textAlign: TextAlign.right,
                  style: base.copyWith(
                      fontSize: size,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                      color: color ?? _ink)),
            ],
          ),
        );

    return DefaultTextStyle(
      style: base,
      child: SizedBox(
        width: 340,
        child: PhysicalShape(
          clipper: const _TicketClipper(),
          color: Colors.white,
          elevation: 3,
          shadowColor: const Color(0x33000000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brend sarlavhasi.
              Container(
                color: accent,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      child: logo != null
                          ? Image.memory(logo!, fit: BoxFit.contain)
                          : Text(_initials(name),
                              style: base.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: accent)),
                    ),
                    const SizedBox(height: 10),
                    Text(name,
                        textAlign: TextAlign.center,
                        style: base.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: onAccent)),
                    const SizedBox(height: 2),
                    Text(order.branch,
                        textAlign: TextAlign.center,
                        style: base.copyWith(
                            fontSize: 12,
                            color: onAccent.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(isAdvance ? 'AVANS CHEKI' : "TO'LOV CHEKI",
                        textAlign: TextAlign.center,
                        style: base.copyWith(
                            fontSize: 13,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w800,
                            color: accent.computeLuminance() > 0.6
                                ? _ink
                                : accent)),
                    const SizedBox(height: 4),
                    Text('Buyurtma № ${order.number}',
                        textAlign: TextAlign.center,
                        style: base.copyWith(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(time,
                        textAlign: TextAlign.center,
                        style: base.copyWith(fontSize: 12, color: _muted)),
                    const _Dashes(),
                    row('Mijoz', order.customerLabel),
                    if (order.customerPhone.isNotEmpty)
                      row('Telefon', order.customerPhone),
                    if (order.installDate != null)
                      row("O'rnatish", formatDate(order.installDate!)),
                    const _Dashes(),
                    for (final i in order.items) ...[
                      Text(
                          [i.type ?? '', if (i.model.isNotEmpty) i.model]
                              .join(' · '),
                          style: base.copyWith(fontWeight: FontWeight.w700)),
                      row(
                          '${i.sizeCount} dona · ${formatArea(i.area)} m² × ${formatNumber(i.pricePerM2)}',
                          formatMoney(i.sum),
                          size: 13),
                      const SizedBox(height: 4),
                    ],
                    const _Dashes(),
                    if (order.discount > 0) ...[
                      row('Mahsulotlar', formatMoney(itemsSum)),
                      row('Chegirma', '− ${formatMoney(order.discount)}'),
                    ],
                    row('Jami summa', formatMoney(order.total), bold: true),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          row(
                              '${isAdvance ? 'Avans' : "To'lov"} · ${payment.method.lower}',
                              formatMoney(payment.amount),
                              bold: true,
                              size: 16),
                          if (payment.method == PayMethod.dollar &&
                              payment.usd != null)
                            row('Dollarda',
                                '\$${formatNumber(payment.usd!)} × ${formatNumber(payment.rate ?? 0)}',
                                size: 12),
                          if (paidSoFar != payment.amount)
                            row("Jami to'langan", formatMoney(paidSoFar)),
                          row('Qoldiq', formatMoney(left),
                              bold: true,
                              color: left > 0
                                  ? const Color(0xFFD9480F)
                                  : const Color(0xFF1E9E5A)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Xaridingiz uchun rahmat!',
                        textAlign: TextAlign.center,
                        style: base.copyWith(fontWeight: FontWeight.w700)),
                    if (phone.isNotEmpty)
                      Text(phone,
                          textAlign: TextAlign.center,
                          style: base.copyWith(fontSize: 12, color: _muted)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final s = words.take(2).map((w) => w.characters.first).join();
    return s.toUpperCase();
  }
}

class _Dashes extends StatelessWidget {
  const _Dashes();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, c) {
          final n = (c.maxWidth / 8).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < n; i++)
                Container(width: 4, height: 1.2, color: const Color(0xFFCFCFD8)),
            ],
          );
        },
      ),
    );
  }
}

/// Pastki qirrasi tishli chek shakli.
class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper();

  @override
  Path getClip(Size size) {
    const r = 14.0, tooth = 8.0;
    final p = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - tooth);
    final n = (size.width / (tooth * 2)).floor();
    final step = size.width / n;
    for (var i = n; i > 0; i--) {
      final x = i * step;
      p.lineTo(x - step / 2, size.height);
      p.lineTo(x - step, size.height - tooth);
    }
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
