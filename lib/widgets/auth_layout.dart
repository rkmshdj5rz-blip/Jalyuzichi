import 'package:flutter/material.dart';

import '../theme.dart';

/// Kirish ekranlari uchun umumiy ko'rinish: sarlavha, matn, kontent
/// va pastda asosiy tugma.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    required this.buttonText,
    required this.onPressed,
    this.loading = false,
    this.showBack = true,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String buttonText;
  final VoidCallback? onPressed;
  final bool loading;
  final bool showBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: showBack),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.lightMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: loading ? null : onPressed,
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(buttonText),
                  ),
                  if (footer != null) ...[const SizedBox(height: 12), footer!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Qo'llab-quvvatlash xizmati" qatori.
class SupportTile extends StatelessWidget {
  const SupportTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Qo'llab-quvvatlash: +998 71 200 00 00")),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0x1A6A35FF),
                child: Icon(Icons.headset_mic_rounded,
                    color: AppColors.primary, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Qo'llab-quvvatlash xizmati",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('+998 71 200 00 00',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.lightMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.lightMuted),
            ],
          ),
        ),
      ),
    );
  }
}
