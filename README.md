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
7. Bosh sahifa: bannerlar, bugungi montajlar va qarzlar, bo'limlar, yaqin montajlar, eslatmalar (qo'ng'iroqcha), yon menyu

Pastki menyu:

- **Buyurtmalar**: panel (muddati o'tgan, bugun/ertaga o'rnatiladigan, sanasiz, umumiy summa, to'langan, qarz, qoldiq), davr va filial filtri, holat filtrlari, qidiruv, tartib, buyurtma kartalari (montaj va to'lov tugmalari), Kassa jurnali. Buyurtmani ochib tahrirlash, o'chirish, mijozga qo'ng'iroq qilish mumkin.
- **Yangi buyurtma**: filial, buyurtmachi, mahsulot turi, model/kod, 1 m² narxi (Narxlardan o'zi qo'yiladi), o'lchamlar (matndan ham), mijoz, manzil, montaj sanasi, chegirma, oldindan to'lov.
- **Narxlar**: mahsulot qo'shish (jalyuzi turi, collection, 1 m² narxi), turlar bo'yicha ro'yxat, tahrirlash va o'chirish. Buyurtmada tur va collection tanlanganda narx o'zi qo'yiladi.
- **Filiallar** (yon menyu va Kabinetda): filial, do'kon, tsex yoki ombor qo'shish, manzil, telefon, mas'ul shaxs, ish vaqti, faol/to'xtatilgan, asosiy filial, o'chirish.
- **To'lov usuli va chek**: avans va to'lovlar naqd, karta yoki dollarda (kurs bilan). Avansli buyurtma saqlanganda do'kon nomi va logosi bilan bezatilgan chek chiqadi: rasm qilib saqlash yoki Telegramga yuborish. Do'kon nomi va logo ro'yxatdan o'tishda kiritiladi, Kabinet > "Do'kon va chek"da o'zgartiriladi.
- **Kabinet**: profil, shu oy natijasi, manzil, tungi rejim, chiqish.

Ma'lumotlar hozircha telefonning o'zida saqlanadi; hisobdan chiqilganda buyurtmalar va narxlar o'chmaydi.

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
- Buyurtmalarni serverda saqlash (bir nechta xodim bir vaqtda ishlashi uchun)
- Tsexdan yuklar, dilerlar va omborxona bo'limlari
- Haqiqiy filiallar va mahsulotlar ro'yxati
