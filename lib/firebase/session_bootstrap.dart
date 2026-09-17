import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/firebase/owner_codec.dart';
import 'package:petdate/firebase/pet_codec.dart';
import 'package:petdate/firebase/pet_photo_storage.dart';
import 'package:petdate/state/profile_provider.dart';

class RemoteSessionSnapshot {
  const RemoteSessionSnapshot({
    this.verifiedAt,
    this.pet,
    this.loadFailed = false,
  });

  final DateTime? verifiedAt;
  final ProfileDraft? pet;

  /// True when Firestore threw (offline / rules). Callers must not treat this
  /// as "no pet" for returning users.
  final bool loadFailed;
}

/// Load users/{uid} + pets/{uid} after a persisted Auth session.
abstract final class SessionBootstrap {
  static Future<RemoteSessionSnapshot?> load() async {
    if (!IdentityRemote.isLiveAuthReady) return null;
    final uid = IdentityRemote.authUid;
    if (uid == null) return null;

    try {
      return await _loadOnce(uid);
    } on Object catch (first) {
      assert(() {
        debugPrint('SessionBootstrap first attempt failed: $first');
        return true;
      }());
      try {
        return await _loadOnce(uid);
      } on Object catch (second) {
        assert(() {
          debugPrint('SessionBootstrap retry failed: $second');
          return true;
        }());
        return const RemoteSessionSnapshot(loadFailed: true);
      }
    }
  }

  static Future<RemoteSessionSnapshot> _loadOnce(String uid) async {
    final user = await FirebaseFirestore.instance
        .collection(IdentityContract.usersCollection)
        .doc(uid)
        .get();
    DateTime? verifiedAt;
    OwnerAgeBand? ownerAgeBand;
    OwnerGender? ownerGender;
    DogExperience? dogExperience;
    if (user.exists) {
      final data = user.data();
      final rawVerified = data?[IdentityContract.verifiedAtField];
      if (rawVerified is Timestamp) {
        verifiedAt = rawVerified.toDate().toUtc();
      }
      ownerAgeBand = OwnerCodec.parseAgeBand(data?[OwnerCodec.ageBandField]);
      ownerGender = OwnerCodec.parseGender(data?[OwnerCodec.genderField]);
      dogExperience =
          OwnerCodec.parseExperience(data?[OwnerCodec.experienceField]);
    }

    final petSnap = await FirebaseFirestore.instance
        .collection(IdentityContract.petsCollection)
        .doc(uid)
        .get();
    var pet = petSnap.exists
        ? PetCodec.toDraft(petSnap.id, petSnap.data())
        : null;
    if (pet != null &&
        (ownerAgeBand != null ||
            ownerGender != null ||
            dogExperience != null)) {
      pet = pet.copyWith(
        ownerAgeBand: ownerAgeBand,
        ownerGender: ownerGender,
        dogExperience: dogExperience,
      );
    }

    return RemoteSessionSnapshot(
      verifiedAt: verifiedAt,
      pet: pet == null
          ? null
          : await PetPhotoStorage.resolveRemoteUrls(pet, uid: uid),
    );
  }
}
