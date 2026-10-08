/// Tasdiqlash kodi qaysi yo'l bilan yuboriladi.
enum CodeChannel { telegram, sms }

/// Telefon raqamga kod yuborish va uni tekshirish.
///
/// Telegram uchun server Telegram Gateway API dan foydalanadi
/// (sendVerificationMessage va checkVerificationStatus). Gateway kaliti
/// faqat serverda saqlanadi, ilovaga hech qachon qo'yilmaydi.
abstract class AuthService {
  Future<void> sendCode(String phone, CodeChannel channel);

  /// Kod to'g'ri bo'lsa true qaytaradi.
  Future<bool> verifyCode(String phone, String code);
}

/// Sinov rejimi: hech narsa yubormaydi, faqat [demoCode] ni qabul qiladi.
class MockAuthService implements AuthService {
  static const demoCode = '12345';

  @override
  Future<void> sendCode(String phone, CodeChannel channel) =>
      Future<void>.delayed(const Duration(milliseconds: 600));

  @override
  Future<bool> verifyCode(String phone, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return code == demoCode;
  }
}

/// Hozircha butun ilova sinov xizmatidan foydalanadi.
AuthService authService = MockAuthService();
