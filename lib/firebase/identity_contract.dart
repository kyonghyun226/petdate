import 'package:flutter/foundation.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/firebase/identity_remote.dart';

/// P0 Firestore + callable contract for A02.
///
/// **NEVER client-write `users/{uid}.verifiedAt`.** Admin / Cloud Functions only.
///
/// Callable (deployed on `petdatinglove`):
/// - name: [markUserVerifiedCallable]
/// - 2nd gen HTTPS callable, region [functionsRegion]
/// - requires Auth
/// - Admin sets `users/{uid}.verifiedAt` to a server timestamp
/// - success `{ uid, verifiedAt }` where `verifiedAt` is ISO-8601
/// - idempotent if already set
/// - `failed-precondition` if the user doc does not exist
///
/// Client flow (after Firebase Auth):
/// 1. [IdentityVerification.ensureUserDocExists] (no verifiedAt field)
/// 2. [IdentityVerification.requestMarkVerified]
/// 3. listen/get `users/{uid}` → [isVerified] unlock
///
/// Without Auth (tests / mock login) the same methods stay local mocks.
abstract final class IdentityContract {
  static const markUserVerifiedCallable = 'markUserVerified';
  static const functionsRegion = 'asia-northeast3';
  static const usersCollection = 'users';
  static const verifiedAtField = 'verifiedAt';
  static const likesCollection = 'likes';
  static const matchesCollection = 'matches';
  static const petsCollection = 'pets';
  static const threadsCollection = 'threads';
  static const messagesCollection = 'messages';
  static const meetProposalsCollection = 'meetProposals';
  static const blocksCollection = 'blocks';
  static const reportsCollection = 'reports';
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

/// A02 call site. Live callable when Firebase Auth is present; mock otherwise.
/// No client write of `verifiedAt`.
abstract final class IdentityVerification {
  /// Ensure `users/{uid}` exists **without** `verifiedAt`.
  ///
  /// Live: create the official MVP stub (`goal`, `searchRadiusKm`, `createdAt`).
  /// Mock: no-op.
  static Future<void> ensureUserDocExists({
    String? uid,
    UserGoal? goal,
  }) async {
    if (IdentityRemote.isLiveAuthReady) {
      final key = goal == UserGoal.walk ? 'walk' : 'friend';
      await IdentityRemote.ensureUserDoc(goal: key);
      return;
    }
    assert(() {
      debugPrint(
        'IdentityVerification.ensureUserDocExists uid=${uid ?? 'mock'} (mock)',
      );
      return true;
    }());
  }

  /// 2nd gen HTTPS callable [IdentityContract.markUserVerifiedCallable]
  /// in [IdentityContract.functionsRegion] when Auth is present.
  ///
  /// Unlock is **not** this return value — listen/get the user doc afterwards.
  /// Mock (no Auth): returns a fake `{ uid, verifiedAt ISO }` without writing.
  static Future<MarkUserVerifiedResult?> requestMarkVerified({
    String? uid,
  }) async {
    if (IdentityRemote.isLiveAuthReady) {
      return IdentityRemote.callMarkUserVerified();
    }
    final resolved = uid ?? 'mock';
    final iso = DateTime.now().toUtc().toIso8601String();
    assert(() {
      debugPrint(
        'IdentityVerification.requestMarkVerified uid=$resolved '
        'callable=${IdentityContract.markUserVerifiedCallable} '
        'region=${IdentityContract.functionsRegion} (mock, no Auth) '
        'verifiedAt=$iso',
      );
      return true;
    }());
    return MarkUserVerifiedResult(uid: resolved, verifiedAtIso: iso);
  }
}
