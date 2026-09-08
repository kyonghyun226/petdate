import 'package:flutter/foundation.dart';

/// P0 Firestore contract: likes / matches create is denied unless
/// `users/{uid}.verifiedAt` exists (server timestamp).
///
/// `verifiedAt` is **Admin / callable-only**. The Flutter client must not
/// write this field on `users/{uid}` directly. After Auth, A02 success calls
/// callable [confirmIdentityCallable], which Admin-sets:
///
/// ```
/// users/{uid}.verifiedAt = FieldValue.serverTimestamp()
/// ```
///
/// TODO(firebase): replace [confirmIdentityMock] with
/// `FirebaseFunctions.instance.httpsCallable(confirmIdentityCallable)`.
abstract final class IdentityContract {
  static const confirmIdentityCallable = 'confirmIdentity';
  static const usersCollection = 'users';
  static const verifiedAtField = 'verifiedAt';
  static const likesCollection = 'likes';
  static const matchesCollection = 'matches';
}

/// A02 success write path. Mock until Cloud Functions is wired.
abstract final class IdentityVerification {
  /// Mock of callable `confirmIdentity`.
  ///
  /// Real implementation: Auth uid → HTTPS callable → Admin SDK merge-set
  /// `users/{uid}.verifiedAt`. Returns the server time the client should
  /// mirror onto [AppSession.verifiedAt].
  static Future<DateTime> confirmIdentityMock({String? uid}) async {
    assert(() {
      debugPrint(
        'IdentityVerification.confirmIdentityMock uid=${uid ?? 'mock'} '
        '(callable ${IdentityContract.confirmIdentityCallable} not wired)',
      );
      return true;
    }());
    return DateTime.now().toUtc();
  }
}
