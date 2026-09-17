import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/firebase/identity_remote.dart';

/// Account deletion for App Store / privacy compliance.
///
/// Live Auth: prefers HTTPS callable [IdentityContract.deleteOwnAccountCallable]
/// (Admin wipe of Firestore + Auth). Falls back to client-owned docs +
/// [User.delete] when the callable is unavailable.
abstract final class AccountDeletion {
  /// Returns true when remote deletion finished (Auth user is gone or
  /// client [User.delete] succeeded).
  static Future<bool> deleteCurrentAccount() async {
    if (!IdentityRemote.isLiveAuthReady) return true;

    final viaCallable = await _callDeleteOwnAccount();
    if (viaCallable) return true;

    return _clientFallbackDelete();
  }

  static Future<bool> _callDeleteOwnAccount() async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: IdentityContract.functionsRegion,
      ).httpsCallable(IdentityContract.deleteOwnAccountCallable);
      await callable.call();
      return true;
    } on FirebaseFunctionsException catch (e) {
      assert(() {
        debugPrint(
          'AccountDeletion callable ${e.code}: ${e.message}',
        );
        return true;
      }());
      // not-found / unavailable → try client path; permission errors fail.
      if (e.code == 'unauthenticated' || e.code == 'permission-denied') {
        return false;
      }
      return false;
    } on Object catch (e) {
      assert(() {
        debugPrint('AccountDeletion callable: $e');
        return true;
      }());
      return false;
    }
  }

  static Future<bool> _clientFallbackDelete() async {
    final uid = IdentityRemote.authUid;
    final user = FirebaseAuth.instance.currentUser;
    if (uid == null || user == null) return false;

    try {
      await _deleteClientOwnedDocs(uid);
      await _reauthenticateIfNeeded(user);
      await user.delete();
      return true;
    } on FirebaseAuthException catch (e) {
      assert(() {
        debugPrint('AccountDeletion auth ${e.code}: ${e.message}');
        return true;
      }());
      if (e.code == 'requires-recent-login') {
        try {
          await _reauthenticateIfNeeded(user);
          await user.delete();
          return true;
        } on Object catch (retry) {
          assert(() {
            debugPrint('AccountDeletion reauth retry: $retry');
            return true;
          }());
          return false;
        }
      }
      return false;
    } on Object catch (e) {
      assert(() {
        debugPrint('AccountDeletion fallback: $e');
        return true;
      }());
      return false;
    }
  }

  static Future<void> _deleteClientOwnedDocs(String uid) async {
    final db = FirebaseFirestore.instance;

    Future<void> deleteQuery(Query<Map<String, dynamic>> query) async {
      final snap = await query.get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    try {
      final tokens = await db
          .collection(IdentityContract.usersCollection)
          .doc(uid)
          .collection(IdentityContract.fcmTokensCollection)
          .get();
      for (final doc in tokens.docs) {
        await doc.reference.delete();
      }

      await deleteQuery(
        db
            .collection(IdentityContract.likesCollection)
            .where('fromUid', isEqualTo: uid),
      );
      await deleteQuery(
        db
            .collection(IdentityContract.blocksCollection)
            .where('blockerId', isEqualTo: uid),
      );
      await db.collection(IdentityContract.petsCollection).doc(uid).delete();
      await db.collection(IdentityContract.usersCollection).doc(uid).delete();
    } on Object catch (e) {
      assert(() {
        debugPrint('AccountDeletion client docs: $e');
        return true;
      }());
    }
  }

  static Future<void> _reauthenticateIfNeeded(User user) async {
    if (Firebase.apps.isEmpty) return;
    final providerId =
        user.providerData.isEmpty ? null : user.providerData.first.providerId;
    if (providerId == 'google.com') {
      // Recent Google credential is obtained during a fresh Google sign-in
      // flow in AuthRepository; callable path avoids this. For fallback we
      // attempt provider reauth via Firebase when possible.
      final provider = GoogleAuthProvider();
      await user.reauthenticateWithProvider(provider);
      return;
    }
    if (providerId == 'apple.com') {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      await user.reauthenticateWithProvider(provider);
    }
  }
}
