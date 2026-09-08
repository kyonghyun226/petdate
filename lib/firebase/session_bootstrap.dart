import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/firebase/pet_codec.dart';
import 'package:petdate/state/profile_provider.dart';

class RemoteSessionSnapshot {
  const RemoteSessionSnapshot({
    this.goal,
    this.verifiedAt,
    this.pet,
  });

  final UserGoal? goal;
  final DateTime? verifiedAt;
  final ProfileDraft? pet;
}

/// Load users/{uid} + pets/{uid} after a persisted Auth session.
abstract final class SessionBootstrap {
  static Future<RemoteSessionSnapshot?> load() async {
    if (!IdentityRemote.isLiveAuthReady) return null;
    final uid = IdentityRemote.authUid;
    if (uid == null) return null;

    final user = await FirebaseFirestore.instance
        .collection(IdentityContract.usersCollection)
        .doc(uid)
        .get();
    UserGoal? goal;
    DateTime? verifiedAt;
    if (user.exists) {
      final data = user.data();
      final rawGoal = data?['goal'] as String?;
      if (rawGoal == 'walk') {
        goal = UserGoal.walk;
      } else if (rawGoal == 'friend') {
        goal = UserGoal.friend;
      }
      final rawVerified = data?[IdentityContract.verifiedAtField];
      if (rawVerified is Timestamp) {
        verifiedAt = rawVerified.toDate().toUtc();
      }
    }

    final petSnap = await FirebaseFirestore.instance
        .collection(IdentityContract.petsCollection)
        .doc(uid)
        .get();
    final pet = petSnap.exists
        ? PetCodec.toDraft(petSnap.id, petSnap.data())
        : null;

    return RemoteSessionSnapshot(
      goal: goal,
      verifiedAt: verifiedAt,
      pet: pet,
    );
  }
}
