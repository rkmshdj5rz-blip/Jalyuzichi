# Jalyuzichi

Jalyuzi (parda) biznesi uchun mobil ilova. Flutter'da yozilgan, iOS va Android uchun.

## Hozir nima bor

Kirish ketma-ketligi:

1. Davlatni tanlash
2. Telefon raqam kiritish
3. SMS kod bilan tasdiqlash (hozircha sinov rejimi, kod `12345`)
4. Ro'yxatdan o'tish (ism)
5. Sinxronlash (ma'lumotlarni yuklash)
6. Manzil kiritish (viloyat, tuman, xaritadan belgilash)
7. Bosh sahifa: bannerlar, xizmatlar bo'limlari, yon menyu, tungi rejim

Logo vaqtinchalik (`lib/widgets/app_logo.dart`), ranglar `lib/theme.dart` da.

## Ishga tushirish

```sh
flutter pub get
flutter run
```

Testlar: `flutter test`.

## Keyingi qadamlar

- Haqiqiy SMS xizmati va server (backend)
- Haqiqiy xarita (Google yoki Yandex)
- Buyurtmalar, narxlar, dilerlar va omborxona bo'limlari
- Yakuniy logo va dizayn
