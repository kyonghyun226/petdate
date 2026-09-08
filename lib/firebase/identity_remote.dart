import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/firebase/identity_contract.dart';

/// Live Firebase Auth / Firestore / Functions access for A02.
///
/// No-ops when Firebase is not initialized or there is no Auth user
/// (widget tests, mock login). The client never writes `verifiedAt`.
@immutable
class RemoteUserSnapshot {
  const RemoteUserSnapshot({this.verifiedAt});

  final DateTime? verifiedAt;
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
  /// If the doc exists, updates `goal` without touching `verifiedAt`.
  static Future<void> ensureUserDoc({required String goal}) async {
    final uid = authUid;
    if (uid == null) return;
    final doc = FirebaseFirestore.instance
        .collection(IdentityContract.usersCollection)
        .doc(uid);
    final snap = await doc.get();
    if (snap.exists) {
      final current = snap.data()?['goal'] as String?;
      if (current != goal) {
        await doc.update({'goal': goal});
      }
      return;
    }
    await doc.set({
      'goal': goal,
      'searchRadiusKm': AppConstants.searchRadiusKm,
      'createdAt': FieldValue.serverTimestamp(),
    });
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

  static RemoteUserSnapshot _fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final raw = snap.data()?[IdentityContract.verifiedAtField];
    DateTime? at;
    if (raw is Timestamp) {
      at = raw.toDate().toUtc();
    }
    return RemoteUserSnapshot(verifiedAt: at);
  }
}
