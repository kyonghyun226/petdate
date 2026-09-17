import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/firebase/identity_remote.dart';

/// Result of [PhoneVerification.sendSmsCode].
@immutable
class PhoneSmsSession {
  const PhoneSmsSession({
    required this.verificationId,
    this.resendToken,
    this.autoLinked = false,
  });

  final String verificationId;
  final int? resendToken;

  /// Android instant verification already linked the phone credential.
  final bool autoLinked;
}

sealed class PhoneVerificationException implements Exception {
  const PhoneVerificationException();
}

class PhoneInvalidNumber extends PhoneVerificationException {
  const PhoneInvalidNumber();
}

class PhoneSmsSendFailed extends PhoneVerificationException {
  const PhoneSmsSendFailed();
}

class PhoneSmsConfirmFailed extends PhoneVerificationException {
  const PhoneSmsConfirmFailed();
}

class PhoneCredentialInUse extends PhoneVerificationException {
  const PhoneCredentialInUse();
}

/// Korean mobile → E.164 (`01012345678` → `+821012345678`).
abstract final class PhoneNumberNormalizer {
  static final _digits = RegExp(r'\D');

  /// Returns E.164 or null if the number is not a plausible KR mobile.
  static String? toE164Kr(String raw) {
    var digits = raw.replaceAll(_digits, '');
    if (digits.startsWith('82') && digits.length >= 11) {
      digits = '0${digits.substring(2)}';
    }
    if (digits.startsWith('0') && digits.length == 11 && digits[1] == '1') {
      return '+82${digits.substring(1)}';
    }
    if (digits.length == 10 && digits.startsWith('1')) {
      return '+82$digits';
    }
    return null;
  }
}

abstract class PhoneVerification {
  /// Send SMS. On mock / no Auth, returns a fake session immediately.
  Future<PhoneSmsSession> sendSmsCode(
    String phoneRaw, {
    int? forceResendingToken,
  });

  /// Confirm OTP and link phone to the current Google/Apple user.
  /// Mock: no-op success. Live: [User.linkWithCredential] / [User.updatePhoneNumber]
  /// then refreshes the ID token so `phone_number` is on the callable claim.
  Future<void> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  });
}

final phoneVerificationProvider = Provider<PhoneVerification>((ref) {
  if (IdentityRemote.isLiveAuthReady) {
    return FirebasePhoneVerification();
  }
  return const MockPhoneVerification();
});

class MockPhoneVerification implements PhoneVerification {
  const MockPhoneVerification();

  static const mockVerificationId = 'mock-verification-id';

  @override
  Future<PhoneSmsSession> sendSmsCode(
    String phoneRaw, {
    int? forceResendingToken,
  }) async {
    final e164 = PhoneNumberNormalizer.toE164Kr(phoneRaw);
    if (e164 == null) throw const PhoneInvalidNumber();
    return const PhoneSmsSession(verificationId: mockVerificationId);
  }

  @override
  Future<void> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final code = smsCode.replaceAll(RegExp(r'\s'), '');
    if (code.length < 4) throw const PhoneSmsConfirmFailed();
  }
}

class FirebasePhoneVerification implements PhoneVerification {
  FirebasePhoneVerification({FirebaseAuth? auth}) : _authOverride = auth;

  final FirebaseAuth? _authOverride;

  FirebaseAuth get _auth {
    if (Firebase.apps.isEmpty) {
      throw const PhoneSmsSendFailed();
    }
    return _authOverride ?? FirebaseAuth.instance;
  }

  @override
  Future<PhoneSmsSession> sendSmsCode(
    String phoneRaw, {
    int? forceResendingToken,
  }) async {
    final e164 = PhoneNumberNormalizer.toE164Kr(phoneRaw);
    if (e164 == null) throw const PhoneInvalidNumber();
    if (_auth.currentUser == null) throw const PhoneSmsSendFailed();

    final completer = Completer<PhoneSmsSession>();

    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (credential) async {
        try {
          await _linkOrUpdate(credential);
          if (!completer.isCompleted) {
            completer.complete(
              const PhoneSmsSession(
                verificationId: '',
                autoLinked: true,
              ),
            );
          }
        } on PhoneVerificationException catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        } on Object {
          if (!completer.isCompleted) {
            completer.completeError(const PhoneSmsSendFailed());
          }
        }
      },
      verificationFailed: (error) {
        assert(() {
          debugPrint(
            'FirebasePhoneVerification.sendSmsCode ${error.code}: '
            '${error.message}',
          );
          return true;
        }());
        if (!completer.isCompleted) {
          completer.completeError(
            error.code == 'invalid-phone-number'
                ? const PhoneInvalidNumber()
                : const PhoneSmsSendFailed(),
          );
        }
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneSmsSession(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneSmsSession(verificationId: verificationId),
          );
        }
      },
    );

    return completer.future;
  }

  @override
  Future<void> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final code = smsCode.replaceAll(RegExp(r'\s'), '');
    if (code.length < 4 || verificationId.isEmpty) {
      throw const PhoneSmsConfirmFailed();
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    await _linkOrUpdate(credential);
  }

  Future<void> _linkOrUpdate(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) throw const PhoneSmsConfirmFailed();

    final hasPhone = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;
    try {
      if (hasPhone) {
        await user.updatePhoneNumber(credential);
      } else {
        await user.linkWithCredential(credential);
      }
    } on FirebaseAuthException catch (error) {
      assert(() {
        debugPrint(
          'FirebasePhoneVerification.link ${error.code}: ${error.message}',
        );
        return true;
      }());
      if (error.code == 'provider-already-linked') {
        // Same provider already on account — treat as success if phone set.
        await user.reload();
        final refreshed = _auth.currentUser;
        if (refreshed?.phoneNumber != null &&
            refreshed!.phoneNumber!.isNotEmpty) {
          await refreshed.getIdToken(true);
          return;
        }
        throw const PhoneSmsConfirmFailed();
      }
      if (error.code == 'credential-already-in-use' ||
          error.code == 'account-exists-with-different-credential') {
        throw const PhoneCredentialInUse();
      }
      if (error.code == 'invalid-verification-code' ||
          error.code == 'invalid-verification-id' ||
          error.code == 'session-expired') {
        throw const PhoneSmsConfirmFailed();
      }
      throw const PhoneSmsConfirmFailed();
    }

    await user.reload();
    await _auth.currentUser?.getIdToken(true);
  }
}
