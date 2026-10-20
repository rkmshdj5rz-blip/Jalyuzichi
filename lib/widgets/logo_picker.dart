import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';

/// Logo tanlash: rasm ko'rinishi, "Yuklash" va "O'chirish".
class LogoPicker extends StatelessWidget {
  const LogoPicker({super.key, required this.logo, required this.onChanged});

  final Uint8List? logo;
  final ValueChanged<Uint8List?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (file == null) return;
      onChanged(await file.readAsBytes());
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Rasmni ochib bo'lmadi")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).inputDecorationTheme.fillColor;
    return Row(
      children: [
        GestureDetector(
          onTap: () => _pick(context),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: logo == null ? fill : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.lightMuted.withValues(alpha: 0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: logo == null
                ? const Icon(Icons.add_photo_alternate_outlined,
                    color: AppColors.lightMuted, size: 30)
                : Image.memory(logo!, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Logo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Text('Chekda chiqadi. Ixtiyoriy.',
                  style: TextStyle(fontSize: 13, color: AppColors.lightMuted)),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _pick(context),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36)),
                    child: Text(logo == null ? 'Yuklash' : 'Almashtirish'),
                  ),
                  if (logo != null) ...[
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => onChanged(null),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          foregroundColor: const Color(0xFFE5484D)),
                      child: const Text("O'chirish"),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
