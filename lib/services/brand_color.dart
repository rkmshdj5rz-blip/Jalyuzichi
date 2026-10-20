import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Logodan asosiy rangni topadi (oq, qora va shaffof piksellardan tashqari).
/// Topilmasa null.
Future<Color?> brandColorFromLogo(Uint8List? bytes) async {
  if (bytes == null) return null;
  try {
    final codec = await ui.instantiateImageCodec(bytes,
        targetWidth: 32, targetHeight: 32);
    final frame = await codec.getNextFrame();
    final data =
        await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    double r = 0, g = 0, b = 0, w = 0;
    for (var i = 0; i < data.lengthInBytes; i += 4) {
      final a = data.getUint8(i + 3);
      if (a < 128) continue;
      final c = Color.fromARGB(
          255, data.getUint8(i), data.getUint8(i + 1), data.getUint8(i + 2));
      final hsl = HSLColor.fromColor(c);
      if (hsl.lightness > 0.92 || hsl.lightness < 0.08) continue;
      // To'yingan ranglar ko'proq hisobga olinadi.
      final weight = 0.2 + hsl.saturation;
      r += c.r * weight;
      g += c.g * weight;
      b += c.b * weight;
      w += weight;
    }
    if (w == 0) return null;
    return Color.from(alpha: 1, red: r / w, green: g / w, blue: b / w);
  } catch (_) {
    return null;
  }
}

/// Nomdan barqaror rang (logo bo'lmaganda).
Color brandColorFromName(String name) {
  const palette = [
    Color(0xFF1F6FEB),
    Color(0xFF0E9F6E),
    Color(0xFFD9480F),
    Color(0xFF7048E8),
    Color(0xFFC2255C),
    Color(0xFF0B7285),
    Color(0xFF5C940D),
    Color(0xFF364FC7),
  ];
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return palette[h % palette.length];
}
