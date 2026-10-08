class Country {
  const Country(this.name, this.flag, this.code, this.digits);

  final String name;
  final String flag;
  final String code;

  /// Kod (masalan +998) dan keyingi raqamlar soni.
  final int digits;
}

const countries = [
  Country("O'zbekiston", '🇺🇿', '+998', 9),
  Country("Qozog'iston", '🇰🇿', '+7', 10),
  Country("Qirg'iziston", '🇰🇬', '+996', 9),
  Country('Turkiya', '🇹🇷', '+90', 10),
  Country('Tojikiston', '🇹🇯', '+992', 9),
  Country('Turkmaniston', '🇹🇲', '+993', 8),
];
