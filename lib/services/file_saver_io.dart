import 'dart:typed_data';

import 'package:gal/gal.dart';

Future<bool> saveImage(Uint8List png, String name) async {
  try {
    if (!await Gal.hasAccess()) {
      if (!await Gal.requestAccess()) return false;
    }
    await Gal.putImageBytes(png, name: name);
    return true;
  } catch (_) {
    return false;
  }
}
