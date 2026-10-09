import 'dart:typed_data';

import 'file_saver_io.dart' if (dart.library.js_interop) 'file_saver_web.dart'
    as impl;

/// Rasmni saqlaydi: telefonda galereyaga, brauzerda yuklab oladi.
/// Muvaffaqiyatli bo'lsa true.
Future<bool> saveImage(Uint8List png, String name) => impl.saveImage(png, name);
