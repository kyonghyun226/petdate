import 'package:petdate/location/geo.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/spark.dart';
import 'package:petdate/state/profile_provider.dart';

/// Likes / matches / chat / pets against Auth+Firestore, or an in-memory mock.
abstract class SocialRepository {
  Stream<List<DiscoveryProfile>> watchExplore({
    required String myUid,
    required Set<String> blockedIds,
  });

  Stream<List<SparkItem>> watchSpark({required String myUid});

  Stream<List<ChatThread>> watchThreads({required String myUid});

  /// Returns true when the like creates a match (mutual likes).
  Future<bool> sendLike({
    required String fromUid,
    required DiscoveryProfile to,
  });

  Future<void> sendText({
    required String matchId,
    required String senderId,
    required String text,
  });

  Future<void> sendMeetup({
    required String matchId,
    required String fromUid,
    required MeetupProposal proposal,
  });

  Future<void> setMeetupStatus({
    required String proposalId,
    required MeetupReceipt receipt,
    MeetupProposal? counter,
  });

  Future<void> upsertPet({
    required String uid,
    required ProfileDraft draft,
  });

  /// Writes approximate latlng + geohash onto pets/{uid}.
  Future<void> updatePetLocation({
    required String uid,
    required ApproxLatLng point,
  });

  Future<ProfileDraft?> readPet(String uid);

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  });

  Future<void> reportTarget({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
  });

  Stream<Set<String>> watchBlockedIds({required String blockerId});
}
