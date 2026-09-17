import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/firebase/owner_codec.dart';
import 'package:petdate/state/profile_provider.dart';

/// Live Firebase Auth / Firestore / Functions access for trust / likes unlock.
///
/// No-ops when Firebase is not initialized or there is no Auth user
/// (widget tests, mock login). The client never writes `verifiedAt`.
@immutable
class RemoteUserSnapshot {
  const RemoteUserSnapshot({
    this.verifiedAt,
    this.petRegOwnerName,
    this.petRegNumber,
    this.petRegPending = false,
    this.ownerAgeBand,
    this.ownerGender,
    this.dogExperience,
  });

  final DateTime? verifiedAt;
  final String? petRegOwnerName;
  final String? petRegNumber;
  final bool petRegPending;
  final OwnerAgeBand? ownerAgeBand;
  final OwnerGender? ownerGender;
  final DogExperience? dogExperience;
}

abstract final class IdentityRemote {
  static bool get isLiveAuthReady {
    try {
      return Firebase.apps.isNotEmpty &&
          FirebaseAuth.instance.currentUser != null;
    } on Object {
      return false;
    }
  }

  static String? get authUid {
    if (!isLiveAuthReady) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Create `users/{authUid}` with the official MVP fields only.
  /// Does **not** set [IdentityContract.verifiedAtField].
  /// If the doc exists, updates optional owner fields without touching
  /// `verifiedAt` or legacy `goal`.
  static Future<void> ensureUserDoc({
    OwnerAgeBand? ownerAgeBand,
    OwnerGender? ownerGender,
    DogExperience? dogExperience,
  }) async {
    final uid = authUid;
    if (uid == null) return;
    final doc = FirebaseFirestore.instance
        .collection(IdentityContract.usersCollection)
        .doc(uid);
    final ownerFields = _ownerFields(
      ownerAgeBand: ownerAgeBand,
      ownerGender: ownerGender,
      dogExperience: dogExperience,
    );
    final snap = await doc.get();
    if (snap.exists) {
      if (ownerFields.isNotEmpty) {
        await doc.update(ownerFields);
      }
      return;
    }
    await doc.set({
      // Legacy required field; no longer chosen in-app.
      'goal': 'friend',
      'searchRadiusKm': AppConstants.searchRadiusKm,
      'createdAt': FieldValue.serverTimestamp(),
      ...ownerFields,
    });
  }

  /// Write pet registration fields for manual review. Never touches verifiedAt.
  static Future<void> submitPetRegistration({
    required String ownerName,
    required String registrationNumber,
  }) async {
    final uid = authUid;
    if (uid == null) return;
    await ensureUserDoc();
    await FirebaseFirestore.instance
        .collection(IdentityContract.usersCollection)
        .doc(uid)
        .update({
      IdentityContract.petRegOwnerNameField: ownerName,
      IdentityContract.petRegNumberField: registrationNumber,
      IdentityContract.petRegStatusField: IdentityContract.petRegStatusPending,
      IdentityContract.petRegSubmittedAtField: FieldValue.serverTimestamp(),
    });
  }

  static Map<String, String> _ownerFields({
    OwnerAgeBand? ownerAgeBand,
    OwnerGender? ownerGender,
    DogExperience? dogExperience,
  }) {
    if (ownerAgeBand == null ||
        ownerGender == null ||
        dogExperience == null) {
      return const {};
    }
    return OwnerCodec.toFirestore(
      ageBand: ownerAgeBand,
      gender: ownerGender,
      experience: dogExperience,
    );
  }

  /// HTTPS callable [IdentityContract.markUserVerifiedCallable].
  /// Returns null on `failed-precondition` (no user doc) or other CF errors.
  static Future<MarkUserVerifiedResult?> callMarkUserVerified() async {
    if (!isLiveAuthReady) return null;
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: IdentityContract.functionsRegion,
      ).httpsCallable(IdentityContract.markUserVerifiedCallable);
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      return MarkUserVerifiedResult(
        uid: data['uid'] as String,
        verifiedAtIso: data['verifiedAt'] as String,
      );
    } on FirebaseFunctionsException catch (e) {
      assert(() {
        debugPrint(
          'IdentityRemote.callMarkUserVerified ${e.code}: ${e.message}',
        );
        return true;
      }());
      return null;
    }
  }

  static Stream<RemoteUserSnapshot>? watchCurrentUserDoc() {
    final uid = authUid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection(IdentityContract.usersCollection)
        .doc(uid)
        .snapshots()
        .map(_fromSnap);
  }

  static Future<RemoteUserSnapshot?> readCurrentUserDoc() async {
    final uid = authUid;
    if (uid == null) return null;
    final snap = await FirebaseFirestore.instance
        .collection(IdentityContract.usersCollection)
        .doc(uid)
        .get();
    if (!snap.exists) return null;
    return _fromSnap(snap);
  }

  static RemoteUserSnapshot _fromSnap(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data();
    final raw = data?[IdentityContract.verifiedAtField];
    DateTime? at;
    if (raw is Timestamp) {
      at = raw.toDate().toUtc();
    }
    final status = data?[IdentityContract.petRegStatusField] as String?;
    return RemoteUserSnapshot(
      verifiedAt: at,
      petRegOwnerName:
          data?[IdentityContract.petRegOwnerNameField] as String?,
      petRegNumber: data?[IdentityContract.petRegNumberField] as String?,
      petRegPending: status == IdentityContract.petRegStatusPending,
      ownerAgeBand: OwnerCodec.parseAgeBand(data?[OwnerCodec.ageBandField]),
      ownerGender: OwnerCodec.parseGender(data?[OwnerCodec.genderField]),
      dogExperience:
          OwnerCodec.parseExperience(data?[OwnerCodec.experienceField]),
    );
  }
}
