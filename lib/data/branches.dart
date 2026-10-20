// Filial va do'konlar.

enum BranchKind {
  branch('Filial'),
  shop("Do'kon"),
  workshop('Tsex'),
  warehouse('Ombor');

  const BranchKind(this.label);
  final String label;
}

class Branch {
  Branch({
    required this.id,
    required this.name,
    this.kind = BranchKind.branch,
    this.address = '',
    this.phone = '',
    this.manager = '',
    this.hours = '',
    this.active = true,
  });

  final String id;
  String name;
  BranchKind kind;
  String address;
  String phone;

  /// Mas'ul shaxs.
  String manager;

  /// Ish vaqti, masalan "09:00 – 19:00".
  String hours;

  /// Faol bo'lmagan filial yangi buyurtmada tanlanmaydi.
  bool active;

  Branch copy() => Branch.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'address': address,
        'phone': phone,
        'manager': manager,
        'hours': hours,
        'active': active,
      };

  factory Branch.fromJson(Map<String, dynamic> j) => Branch(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: BranchKind.values.asNameMap()[j['kind']] ?? BranchKind.branch,
        address: j['address'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        manager: j['manager'] as String? ?? '',
        hours: j['hours'] as String? ?? '',
        active: j['active'] as bool? ?? true,
      );
}
