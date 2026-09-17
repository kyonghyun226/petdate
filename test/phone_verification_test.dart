import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/auth/phone_verification.dart';

void main() {
  group('PhoneNumberNormalizer.toE164Kr', () {
    test('normalizes common Korean mobile formats', () {
      expect(PhoneNumberNormalizer.toE164Kr('01012345678'), '+821012345678');
      expect(PhoneNumberNormalizer.toE164Kr('010-1234-5678'), '+821012345678');
      expect(PhoneNumberNormalizer.toE164Kr('+82 10 1234 5678'), '+821012345678');
      expect(PhoneNumberNormalizer.toE164Kr('821012345678'), '+821012345678');
      expect(PhoneNumberNormalizer.toE164Kr('1012345678'), '+821012345678');
    });

    test('rejects invalid numbers', () {
      expect(PhoneNumberNormalizer.toE164Kr(''), isNull);
      expect(PhoneNumberNormalizer.toE164Kr('02-123-4567'), isNull);
      expect(PhoneNumberNormalizer.toE164Kr('0101234'), isNull);
      expect(PhoneNumberNormalizer.toE164Kr('abc'), isNull);
    });
  });

  group('MockPhoneVerification', () {
    const mock = MockPhoneVerification();

    test('sendSmsCode requires a valid KR mobile', () async {
      await expectLater(
        mock.sendSmsCode('bad'),
        throwsA(isA<PhoneInvalidNumber>()),
      );
      final session = await mock.sendSmsCode('01012345678');
      expect(session.verificationId, MockPhoneVerification.mockVerificationId);
      expect(session.autoLinked, isFalse);
    });

    test('confirmSmsCode accepts a short OTP of at least 4 digits', () async {
      await expectLater(
        mock.confirmSmsCode(verificationId: 'id', smsCode: '12'),
        throwsA(isA<PhoneSmsConfirmFailed>()),
      );
      await mock.confirmSmsCode(verificationId: 'id', smsCode: '1234');
    });
  });
}
