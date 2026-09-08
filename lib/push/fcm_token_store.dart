import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/firebase/identity_remote.dart';

/// Client-writable FCM token fields. Never includes verifiedAt.
///
/// Path: `users/{uid}/fcmTokens/{sha256(token)}` — infra contract (#12).
abstract final class FcmTokenFields {
  static const token = 'token';
  static const platform = 'platform';
  static const updatedAt = 'updatedAt';

  static const platforms = {'ios', 'android'};

  static Map<String, Object> clientWriteMap({
    required String tokenValue,
    required String platformValue,
    required Object updatedAtValue,
  }) {
    return {
      token: tokenValue,
      platform: platformValue,
      updatedAt: updatedAtValue,
    };
  }

  /// 64 lowercase hex. Do not use the raw FCM token as the doc id.
  static String documentId(String tokenValue) {
    return sha256.convert(utf8.encode(tokenValue)).toString();
  }
}

abstract class PushTokenStore {
  Future<void> upsert({required String token, required String platform});
  Future<void> clear({required String token});
  Future<void> clearAllForCurrentUser();
}

class NoopPushTokenStore implements PushTokenStore {
  const NoopPushTokenStore();

  @override
  Future<void> upsert({required String token, required String platform}) async {}

  @override
  Future<void> clear({required String token}) async {}

  @override
  Future<void> clearAllForCurrentUser() async {}
}

class RecordingPushTokenStore implements PushTokenStore {
  final writes = <Map<String, String>>[];
  final cleared = <String>[];
  int clearAllCount = 0;

  @override
  Future<void> upsert({required String token, required String platform}) async {
    writes.add({'token': token, 'platform': platform});
  }

  @override
  Future<void> clear({required String token}) async {
    cleared.add(token);
  }

  @override
  Future<void> clearAllForCurrentUser() async {
    clearAllCount += 1;
  }
}

/// `users/{uid}/fcmTokens/{tokenHash}` — owner write only.
class FirestorePushTokenStore implements PushTokenStore {
  FirestorePushTokenStore({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>>? _col(String uid) {
    return _db
        .collection(IdentityContract.usersCollection)
        .doc(uid)
        .collection(IdentityContract.fcmTokensCollection);
  }

  @override
  Future<void> upsert({required String token, required String platform}) async {
    final uid = IdentityRemote.authUid;
    if (uid == null) return;
    final user = await IdentityRemote.readCurrentUserDoc();
    if (user == null || user.verifiedAt == null) return;
    if (!FcmTokenFields.platforms.contains(platform)) return;
    if (token.length < 32 || token.length > 4096) return;

    await _col(uid)!
        .doc(FcmTokenFields.documentId(token))
        .set(
          FcmTokenFields.clientWriteMap(
            tokenValue: token,
            platformValue: platform,
            updatedAtValue: FieldValue.serverTimestamp(),
          ),
        );
  }

  @override
  Future<void> clear({required String token}) async {
    final uid = IdentityRemote.authUid;
    if (uid == null) return;
    try {
      await _col(uid)!.doc(FcmTokenFields.documentId(token)).delete();
    } on Object catch (e) {
      assert(() {
        debugPrint('FirestorePushTokenStore.clear: $e');
        return true;
      }());
    }
  }

  @override
  Future<void> clearAllForCurrentUser() async {
    final uid = IdentityRemote.authUid;
    if (uid == null) return;
    try {
      final snap = await _col(uid)!.get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } on Object catch (e) {
      assert(() {
        debugPrint('FirestorePushTokenStore.clearAllForCurrentUser: $e');
        return true;
      }());
    }
  }
}

PushTokenStore createDefaultPushTokenStore() {
  if (!IdentityRemote.isLiveAuthReady) return const NoopPushTokenStore();
  return FirestorePushTokenStore();
}

/// Live logout path. No-op without Auth. Call **before** `signOut`.
abstract final class FcmTokenRemote {
  static Future<void> deleteOwnTokens() async {
    if (!IdentityRemote.isLiveAuthReady) return;
    await FirestorePushTokenStore().clearAllForCurrentUser();
  }
}
