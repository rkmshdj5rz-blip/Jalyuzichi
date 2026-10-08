import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Foydalanuvchi ma'lumotlari. Hozircha telefonning o'zida saqlanadi,
/// keyinchalik server bilan almashtiriladi.
class AppState extends ChangeNotifier {
  AppState._(this._prefs);

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppState._(prefs);
  }

  final SharedPreferences _prefs;

  String get countryCode => _prefs.getString('countryCode') ?? '+998';
  String get phone => _prefs.getString('phone') ?? '';
  String get name => _prefs.getString('name') ?? '';
  String get region => _prefs.getString('region') ?? '';
  String get district => _prefs.getString('district') ?? '';
  bool get isLoggedIn => _prefs.getBool('loggedIn') ?? false;
  bool get hasAddress => region.isNotEmpty && district.isNotEmpty;
  ThemeMode get themeMode =>
      (_prefs.getBool('dark') ?? false) ? ThemeMode.dark : ThemeMode.light;

  Future<void> setCountry(String code) async {
    await _prefs.setString('countryCode', code);
    notifyListeners();
  }

  Future<void> setPhone(String phone) async {
    await _prefs.setString('phone', phone);
    notifyListeners();
  }

  Future<void> register(String name) async {
    await _prefs.setString('name', name);
    await _prefs.setBool('loggedIn', true);
    notifyListeners();
  }

  Future<void> setAddress(String region, String district) async {
    await _prefs.setString('region', region);
    await _prefs.setString('district', district);
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    await _prefs.setBool('dark', dark);
    notifyListeners();
  }

  Future<void> logout() async {
    final dark = _prefs.getBool('dark');
    await _prefs.clear();
    if (dark != null) await _prefs.setBool('dark', dark);
    notifyListeners();
  }
}

/// Ilova bo'ylab [AppState] ga kirish uchun.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
