import 'package:flutter/foundation.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/state/profile_provider.dart';

/// P0 Firestore + callable contract for trust / likes unlock.
///
/// **NEVER client-write `users/{uid}.verifiedAt`.** Admin / Cloud Functions only.
///
/// Pet registration (manual review):
/// 1. Client writes owner name + registration number + `petRegStatus: pending`
/// 2. Operator confirms against 국가동물보호정보시스템
/// 3. Admin sets `users/{uid}.verifiedAt` (console or [markUserVerifiedCallable])
/// 4. Client listen/get → [isVerified] unlock
///
/// Without Auth (tests / mock login) submit stays local on [UserDoc].
abstract final class IdentityContract {
  static const markUserVerifiedCallable = 'markUserVerified';
  static const deleteOwnAccountCallable = 'deleteOwnAccount';
  static const functionsRegion = 'asia-northeast3';
  static const usersCollection = 'users';
  static const verifiedAtField = 'verifiedAt';
  static const petRegOwnerNameField = 'petRegOwnerName';
  static const petRegNumberField = 'petRegNumber';
  static const petRegStatusField = 'petRegStatus';
  static const petRegSubmittedAtField = 'petRegSubmittedAt';
  static const petRegStatusPending = 'pending';
  static const likesCollection = 'likes';
  static const matchesCollection = 'matches';
  static const petsCollection = 'pets';
  static const threadsCollection = 'threads';
  static const messagesCollection = 'messages';
  static const meetProposalsCollection = 'meetProposals';
  static const blocksCollection = 'blocks';
  static const reportsCollection = 'reports';
  static const fcmTokensCollection = 'fcmTokens';
  static const failedPrecondition = 'failed-precondition';
}

/// Payload of a successful `markUserVerified` call (admin / legacy).
@immutable
class MarkUserVerifiedResult {
  const MarkUserVerifiedResult({
    required this.uid,
    required this.verifiedAtIso,
  });

  final String uid;
  final String verifiedAtIso;
}

/// Trust call sites. Live Firestore when Auth is present; mock otherwise.
/// No client write of `verifiedAt`.
abstract final class IdentityVerification {
  /// Ensure `users/{uid}` exists **without** `verifiedAt`.
  ///
  /// Live: create/update the official MVP stub (`goal`, `searchRadiusKm`,
  /// `createdAt`) and optional owner profile fields. `goal` is always
  /// `'friend'` (legacy field; no in-app choice).
  /// Mock: no-op.
  static Future<void> ensureUserDocExists({
    String? uid,
    OwnerAgeBand? ownerAgeBand,
    OwnerGender? ownerGender,
    DogExperience? dogExperience,
  }) async {
    if (IdentityRemote.isLiveAuthReady) {
      await IdentityRemote.ensureUserDoc(
        ownerAgeBand: ownerAgeBand,
        ownerGender: ownerGender,
        dogExperience: dogExperience,
      );
      return;
    }
    assert(() {
      debugPrint(
        'IdentityVerification.ensureUserDocExists uid=${uid ?? 'mock'} (mock)',
      );
      return true;
    }());
  }

  /// Submit pet registration for manual review. Never sets `verifiedAt`.
  static Future<void> submitPetRegistration({
    required String ownerName,
    required String registrationNumber,
  }) async {
    if (IdentityRemote.isLiveAuthReady) {
      await IdentityRemote.submitPetRegistration(
        ownerName: ownerName,
        registrationNumber: registrationNumber,
      );
      return;
    }
    assert(() {
      debugPrint(
        'IdentityVerification.submitPetRegistration '
        'owner=$ownerName reg=$registrationNumber (mock)',
      );
      return true;
    }());
  }

  /// Admin / legacy HTTPS callable. App A02 no longer calls this after
  /// switching to manual pet-registration review.
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
