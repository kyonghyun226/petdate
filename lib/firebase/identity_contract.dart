import 'package:flutter/foundation.dart';

/// P0: `likes` / `matches` create is denied unless `users/{uid}.verifiedAt`
/// exists (server timestamp). See `firestore.rules`.
///
/// **Client must never `set` / `update` `users/{uid}.verifiedAt`.**
/// That field is Admin / Cloud Functions only.
///
/// A02 flow in this PR:
/// 1. Mock success (local UI unlock), or
/// 2. TODO: HTTPS callable [confirmIdentityCallable] — server writes
///    `verifiedAt`. Client then **reads / listens** `users/{uid}`.
abstract final class IdentityContract {
  static const confirmIdentityCallable = 'confirmIdentity';
  static const usersCollection = 'users';
  static const verifiedAtField = 'verifiedAt';
  static const likesCollection = 'likes';
  static const matchesCollection = 'matches';
}

/// A02 → Functions call site. No Firestore writes.
abstract final class IdentityVerification {
  /// Request the server to mark the user verified.
  ///
  /// TODO(firebase):
  /// ```
  /// await FirebaseFunctions.instance
  ///     .httpsCallable(IdentityContract.confirmIdentityCallable)
  ///     .call();
  /// ```
  /// Then listen/get `users/{uid}` for [IdentityContract.verifiedAtField].
  ///
  /// Mock: returns `true` only. Does **not** write Firestore.
  static Future<bool> requestMarkVerified({String? uid}) async {
    assert(() {
      debugPrint(
        'IdentityVerification.requestMarkVerified uid=${uid ?? 'mock'} '
        'callable=${IdentityContract.confirmIdentityCallable} (TODO, mock ok)',
      );
      return true;
    }());
    return true;
  }
}
