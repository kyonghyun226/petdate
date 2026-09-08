import 'package:flutter/foundation.dart';

/// P0 Firestore + callable contract for A02.
///
/// **NEVER client-write `users/{uid}.verifiedAt`.** Admin / Cloud Functions only.
///
/// Callable (wire after PR #2+#3):
/// - name: [markUserVerifiedCallable]
/// - 2nd gen HTTPS callable, region [functionsRegion]
/// - requires Auth
/// - Admin sets `users/{uid}.verifiedAt` to a server timestamp
/// - success `{ uid, verifiedAt }` where `verifiedAt` is ISO-8601
/// - idempotent if already set
/// - `failed-precondition` if the user doc does not exist
///
/// Client flow:
/// 1. [IdentityVerification.ensureUserDocExists] (no verifiedAt field)
/// 2. [IdentityVerification.requestMarkVerified]
/// 3. listen/get `users/{uid}` → [isVerified] unlock
abstract final class IdentityContract {
  static const markUserVerifiedCallable = 'markUserVerified';
  static const functionsRegion = 'asia-northeast3';
  static const usersCollection = 'users';
  static const verifiedAtField = 'verifiedAt';
  static const likesCollection = 'likes';
  static const matchesCollection = 'matches';
  static const failedPrecondition = 'failed-precondition';
}

/// Payload of a successful `markUserVerified` call.
@immutable
class MarkUserVerifiedResult {
  const MarkUserVerifiedResult({
    required this.uid,
    required this.verifiedAtIso,
  });

  final String uid;
  final String verifiedAtIso;
}

/// A02 call site. Mock until Functions is deployed. No Firestore writes.
abstract final class IdentityVerification {
  /// Ensure `users/{uid}` exists **without** `verifiedAt`.
  ///
  /// TODO(firebase): create the user doc if missing. Do not set verifiedAt.
  static Future<void> ensureUserDocExists({String? uid}) async {
    assert(() {
      debugPrint(
        'IdentityVerification.ensureUserDocExists uid=${uid ?? 'mock'} (TODO)',
      );
      return true;
    }());
  }

  /// 2nd gen HTTPS callable [IdentityContract.markUserVerifiedCallable]
  /// in [IdentityContract.functionsRegion].
  ///
  /// TODO(firebase):
  /// ```
  /// FirebaseFunctions.instanceFor(region: IdentityContract.functionsRegion)
  ///   .httpsCallable(IdentityContract.markUserVerifiedCallable)
  ///   .call();
  /// ```
  /// Map success to [MarkUserVerifiedResult]. Treat already-set as success.
  /// Surface [IdentityContract.failedPrecondition] if there is no user doc.
  ///
  /// Unlock is **not** this return value — listen the user doc afterwards.
  /// Mock: returns a fake `{ uid, verifiedAt ISO }` without writing.
  static Future<MarkUserVerifiedResult?> requestMarkVerified({
    String? uid,
  }) async {
    final resolved = uid ?? 'mock';
    final iso = DateTime.now().toUtc().toIso8601String();
    assert(() {
      debugPrint(
        'IdentityVerification.requestMarkVerified uid=$resolved '
        'callable=${IdentityContract.markUserVerifiedCallable} '
        'region=${IdentityContract.functionsRegion} (TODO, mock ok) '
        'verifiedAt=$iso',
      );
      return true;
    }());
    return MarkUserVerifiedResult(uid: resolved, verifiedAtIso: iso);
  }
}
