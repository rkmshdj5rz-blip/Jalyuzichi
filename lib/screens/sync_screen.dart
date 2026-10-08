import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/app_logo.dart';
import 'home_screen.dart';

const _steps = [
  'Server bilan ulanish',
  "Foydalanuvchi ma'lumotlari",
  'Viloyat va tumanlar',
  'Mahsulot turlari',
  "Narxlar ro'yxati",
  "Dilerlar va do'konlar",
  'Omborxona qoldiqlari',
  'Buyurtmalar tarixi',
  'Bannerlar',
];

/// Kirishdan keyin ma'lumotlarni yuklash (sinxronlash) ekrani.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  int _done = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Hozircha yuklash taqlid qilinadi; server ulangach haqiqiy so'rovlar bo'ladi.
    _timer = Timer.periodic(const Duration(milliseconds: 280), (t) {
      if (_done >= _steps.length) {
        t.cancel();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
        return;
      }
      setState(() => _done++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _done / _steps.length;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const AppLogo(size: 64, showName: false),
              const SizedBox(height: 16),
              const Text(
                'Sinxronlash',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                "Ma'lumotlar yuklanmoqda, biroz kuting",
                style: TextStyle(color: AppColors.lightMuted),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _steps.length,
                  itemBuilder: (context, i) {
                    final done = i < _done;
                    final current = i == _done;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: done
                                ? const Icon(Icons.check_circle_rounded,
                                    color: AppColors.success, size: 22)
                                : current
                                    ? const Padding(
                                        padding: EdgeInsets.all(3),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.circle_outlined,
                                        color: AppColors.lightMuted, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            done ? '${_steps[i]} yuklandi' : _steps[i],
                            style: TextStyle(
                              color: done || current
                                  ? null
                                  : AppColors.lightMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  const Text('Yuklanmoqda'),
                  const Spacer(),
                  Text('${(progress * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
