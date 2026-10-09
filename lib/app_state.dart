import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/branches.dart';
import 'data/orders.dart';
import 'data/products.dart';
import 'data/sample_orders.dart';

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

  /// Telefonda saqlangan buyurtmalar, eng yangisi birinchi.
  List<Order> get orders {
    final raw = _prefs.getStringList('orders') ?? const [];
    return [
      for (final o in raw.reversed)
        Order.fromJson(jsonDecode(o) as Map<String, dynamic>),
    ];
  }

  /// Buyurtmani yangilaydi (to'lov qo'shish, o'rnatildi deb belgilash).
  Future<void> updateOrder(Order order) async {
    final raw = _prefs.getStringList('orders') ?? <String>[];
    final updated = [
      for (final o in raw)
        (jsonDecode(o) as Map<String, dynamic>)['number'] == order.number
            ? jsonEncode(order.toJson())
            : o,
    ];
    await _prefs.setStringList('orders', updated);
    notifyListeners();
  }

  /// Bir nechta buyurtmani birdaniga qo'shadi (namuna ma'lumotlar uchun).
  Future<void> addOrders(List<Order> orders) async {
    final raw = _prefs.getStringList('orders') ?? <String>[];
    await _prefs.setStringList(
        'orders', [...raw, for (final o in orders) jsonEncode(o.toJson())]);
    await _prefs.setInt('nextOrderNumber', orders.last.number + 1);
    notifyListeners();
  }

  /// Buyurtmani o'chiradi.
  Future<void> deleteOrder(int number) async {
    final raw = _prefs.getStringList('orders') ?? <String>[];
    await _prefs.setStringList('orders', [
      for (final o in raw)
        if ((jsonDecode(o) as Map<String, dynamic>)['number'] != number) o,
    ]);
    notifyListeners();
  }

  bool get hasSamples => orders.any((o) => o.customerName.startsWith(samplePrefix));

  /// Namuna buyurtmalarni o'chiradi (haqiqiy buyurtmalar qoladi).
  Future<void> removeSamples() async {
    final raw = _prefs.getStringList('orders') ?? <String>[];
    await _prefs.setStringList('orders', [
      for (final o in raw)
        if (!((jsonDecode(o) as Map<String, dynamic>)['customerName'] as String? ?? '')
            .startsWith(samplePrefix))
          o,
    ]);
    notifyListeners();
  }

  /// Filial va do'konlar.
  List<Branch> get branches {
    final raw = _prefs.getString('branches');
    if (raw == null) {
      return [
        for (var i = 0; i < defaultBranchNames.length; i++)
          Branch(id: 'b${i + 1}', name: defaultBranchNames[i]),
      ];
    }
    return [
      for (final b in jsonDecode(raw) as List)
        Branch.fromJson(b as Map<String, dynamic>),
    ];
  }

  /// Yangi buyurtmada tanlanadigan faol filiallar.
  List<Branch> get activeBranches => branches.where((b) => b.active).toList();

  /// Asosiy filial (yangi buyurtmada birinchi tanlangan bo'ladi).
  String? get mainBranchId => _prefs.getString('mainBranch');

  Branch? get mainBranch {
    final active = activeBranches;
    if (active.isEmpty) return null;
    return active.where((b) => b.id == mainBranchId).firstOrNull ?? active.first;
  }

  Future<void> setMainBranch(String id) async {
    await _prefs.setString('mainBranch', id);
    notifyListeners();
  }

  Future<void> _saveBranches(List<Branch> list) => _prefs.setString(
      'branches', jsonEncode([for (final b in list) b.toJson()]));

  /// Filialni qo'shadi yoki o'zgartiradi. Nomi o'zgarsa, eski buyurtmalardagi
  /// nom ham yangilanadi.
  Future<void> saveBranch(Branch branch) async {
    final list = branches;
    final i = list.indexWhere((b) => b.id == branch.id);
    if (i < 0) {
      list.add(branch);
    } else {
      final oldName = list[i].name;
      list[i] = branch;
      if (oldName != branch.name) {
        final raw = _prefs.getStringList('orders') ?? <String>[];
        await _prefs.setStringList('orders', [
          for (final o in raw)
            () {
              final j = jsonDecode(o) as Map<String, dynamic>;
              if (j['branch'] != oldName) return o;
              j['branch'] = branch.name;
              return jsonEncode(j);
            }(),
        ]);
      }
    }
    await _saveBranches(list);
    notifyListeners();
  }

  Future<void> deleteBranch(String id) async {
    await _saveBranches(branches.where((b) => b.id != id).toList());
    if (mainBranchId == id) await _prefs.remove('mainBranch');
    notifyListeners();
  }

  /// Filialdagi buyurtmalar soni.
  int ordersIn(Branch b) => orders.where((o) => o.branch == b.name).length;

  /// Mahsulotlar katalogi (tur, collection, narx).
  List<Product> get products {
    final raw = _prefs.getString('products');
    if (raw == null) return defaultProducts();
    return [
      for (final p in jsonDecode(raw) as List)
        Product.fromJson(p as Map<String, dynamic>),
    ];
  }

  Future<void> _saveProducts(List<Product> list) => _prefs.setString(
      'products', jsonEncode([for (final p in list) p.toJson()]));

  /// Tur va collection bo'yicha mahsulotni topadi (katta-kichik harf farqsiz).
  Product? findProduct(String type, String collection) {
    final t = type.trim().toLowerCase(), c = collection.trim().toLowerCase();
    return products
        .where((p) =>
            p.type.toLowerCase() == t && p.collection.toLowerCase() == c)
        .firstOrNull;
  }

  /// Mahsulotni qo'shadi yoki o'zgartiradi.
  Future<void> saveProduct(Product product) async {
    final list = products;
    final i = list.indexWhere((p) => p.id == product.id);
    if (i < 0) {
      list.add(product);
    } else {
      list[i] = product;
    }
    await _saveProducts(list);
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await _saveProducts(products.where((p) => p.id != id).toList());
    notifyListeners();
  }

  /// Do'kon yoki brend nomi (chekda chiqadi).
  String get shopName => _prefs.getString('shopName') ?? '';

  /// Do'kon logosi (rasm baytlari), bo'lmasa null.
  Uint8List? get shopLogo {
    final raw = _prefs.getString('shopLogo');
    return raw == null ? null : base64Decode(raw);
  }

  /// Chekning pastida chiqadigan telefon.
  String get shopPhone => _prefs.getString('shopPhone') ?? '';

  Future<void> setShop({
    required String name,
    required String phone,
    Uint8List? logo,
    bool removeLogo = false,
  }) async {
    await _prefs.setString('shopName', name);
    await _prefs.setString('shopPhone', phone);
    if (logo != null) {
      await _prefs.setString('shopLogo', base64Encode(logo));
    } else if (removeLogo) {
      await _prefs.remove('shopLogo');
    }
    notifyListeners();
  }

  /// Oxirgi ishlatilgan dollar kursi.
  double get usdRate => _prefs.getDouble('usdRate') ?? 12800;

  Future<void> setUsdRate(double rate) async {
    if (rate > 0) await _prefs.setDouble('usdRate', rate);
  }

  /// Keyingi buyurtma raqami.
  int get nextOrderNumber => _prefs.getInt('nextOrderNumber') ?? 1001;

  Future<void> addOrder(Order order) async {
    final raw = _prefs.getStringList('orders') ?? <String>[];
    await _prefs.setStringList(
        'orders', [...raw, jsonEncode(order.toJson())]);
    await _prefs.setInt('nextOrderNumber', order.number + 1);
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    await _prefs.setBool('dark', dark);
    notifyListeners();
  }

  /// Hisobdan chiqish. Buyurtmalar, narxlar va tungi rejim telefonda qoladi,
  /// faqat shaxsiy ma'lumotlar o'chiriladi.
  Future<void> logout() async {
    for (final k in ['phone', 'name', 'region', 'district', 'loggedIn']) {
      await _prefs.remove(k);
    }
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
