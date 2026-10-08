# Jalyuzichi

Jalyuzi (parda) biznesi uchun mobil ilova. Flutter'da yozilgan, iOS va Android uchun.

## Hozir nima bor

Kirish ketma-ketligi:

1. Davlatni tanlash
2. Telefon raqam kiritish
3. Kod bilan tasdiqlash: kod Telegram'ga yuboriladi, xohlasa SMS orqali olsa ham bo'ladi (hozircha sinov rejimi, kod `12345`)
4. Ro'yxatdan o'tish (ism)
5. Sinxronlash (ma'lumotlarni yuklash)
6. Manzil kiritish (viloyat, tuman, xaritadan belgilash)
7. Bosh sahifa: bannerlar, xizmatlar bo'limlari, yon menyu, tungi rejim

Logo `lib/widgets/app_logo.dart` da, ranglar `lib/theme.dart` da.

## Ishga tushirish

```sh
flutter pub get
flutter run
```

Testlar: `flutter test`.

## Keyingi qadamlar

- Server (backend): kodni Telegram Gateway API orqali yuborish
  (`sendVerificationMessage`, `checkVerificationStatus`, gateway.telegram.org)
  va zaxira sifatida SMS xizmati (masalan Eskiz yoki Play Mobile).
  Gateway kaliti faqat serverda turadi; ilovada `lib/services/auth_service.dart`
  dagi `MockAuthService` server bilan ishlaydigan xizmatga almashtiriladi.
- Haqiqiy xarita (Google yoki Yandex)
- Buyurtmalar, narxlar, dilerlar va omborxona bo'limlari
