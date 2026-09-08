import 'package:flutter/foundation.dart';

/// P0: `likes` / `matches` create is denied unless `users/{uid}.verifiedAt`
/// exists (server timestamp). See `firestore.rules`.
///
/// **Client must never `set` / `update` `users/{uid}.verifiedAt`.**
/// Admin / Cloud Functions only.
///
/// Flow: ensure users doc exists → call [markUserVerifiedCallable] →
/// **listen** `users/{uid}` and unlock when `verifiedAt` appears.
abstract final class IdentityContract {
  static const markUserVerifiedCallable = 'markUserVerified';
  static const functionsRegion = 'asia-northeast3';
  static const usersCollection = 'users';
  static const verifiedAtField = 'verifiedAt';
  static const likesCollection = 'likes';
  static const matchesCollection = 'matches';
}

/// A02 → 2nd gen HTTPS callable call site. No Firestore writes.
abstract final class IdentityVerification {
  /// Request the server to mark the signed-in user verified.
  ///
  /// TODO(firebase) — 2nd gen HTTPS callable, [IdentityContract.functionsRegion]:
  /// `markUserVerified` requires Auth; Admin sets users/{uid}.verifiedAt
  /// (server timestamp). Success `{ uid, verifiedAt ISO }`. Idempotent if
  /// already set. `failed-precondition` if no user doc.
  ///
  /// After the callable returns, **listen** the user doc — do not write
  /// `verifiedAt` from the client. Mock: returns `true` only.
  static Future<bool> requestMarkVerified({String? uid}) async {
    assert(() {
      debugPrint(
        'IdentityVerification.requestMarkVerified uid=${uid ?? 'mock'} '
        'callable=${IdentityContract.markUserVerifiedCallable} '
        'region=${IdentityContract.functionsRegion} (TODO, mock ok)',
      );
      return true;
    }());
    return true;
  }
}
