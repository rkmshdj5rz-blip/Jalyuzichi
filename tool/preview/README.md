# Sinov havolasi (Claude Artifact)

Ilovaning brauzer versiyasi Claude ichidagi sinov havolasida ochiladi.

1. `flutter build web --release --no-web-resources-cdn --pwa-strategy=none`
2. `build/web` dagi fayllarni `jalyuzichi.html` yoniga ko'chiring.
3. `python3 patch_bootstrap.py <papka>/flutter_bootstrap.js`
4. `jalyuzichi.html` ni `db` va `user` imkoniyatlari bilan e'lon qiling.

`jalyuzichi.html` ilova xotirasini (`flutter.*` kalitlari) har bir
foydalanuvchining shaxsiy `data/users/<id>` bo'limida ham saqlaydi va
ochilganda qaytaradi: sinov oynasi brauzer xotirasini tozalab yuborsa ham
ro'yxatdan o'tish va buyurtmalar yo'qolmaydi.
