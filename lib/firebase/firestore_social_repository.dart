import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/data/social_repository.dart';
import 'package:petdate/firebase/firestore_ids.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/firebase/pet_codec.dart';
import 'package:petdate/location/geo.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/spark.dart';
import 'package:petdate/state/profile_provider.dart';

/// Live Firestore access. Call only when [IdentityRemote.isLiveAuthReady].
class FirestoreSocialRepository implements SocialRepository {
  FirestoreSocialRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _pets =>
      _db.collection(IdentityContract.petsCollection);

  CollectionReference<Map<String, dynamic>> get _likes =>
      _db.collection(IdentityContract.likesCollection);

  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection(IdentityContract.matchesCollection);

  CollectionReference<Map<String, dynamic>> get _threads =>
      _db.collection(IdentityContract.threadsCollection);

  CollectionReference<Map<String, dynamic>> get _proposals =>
      _db.collection(IdentityContract.meetProposalsCollection);

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _db.collection(IdentityContract.blocksCollection);

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection(IdentityContract.reportsCollection);

  @override
  Stream<List<DiscoveryProfile>> watchExplore({
    required String myUid,
    required Set<String> blockedIds,
  }) {
    return _pets.snapshots().asyncMap((snap) async {
      final incoming = await _incomingLikeUids(myUid);
      final out = <DiscoveryProfile>[];
      for (final doc in snap.docs) {
        if (doc.id == myUid || blockedIds.contains(doc.id)) continue;
        final profile = PetCodec.toDiscovery(
          doc.id,
          doc.data(),
          likedMe: incoming.contains(doc.id),
        );
        if (profile != null) out.add(profile);
      }
      return out;
    });
  }

  Future<Set<String>> _incomingLikeUids(String myUid) async {
    final snap = await _likes.where('toOwnerId', isEqualTo: myUid).get();
    return {for (final doc in snap.docs) doc.data()['fromUid'] as String};
  }

  @override
  Stream<List<SparkItem>> watchSpark({required String myUid}) {
    final controller = StreamController<List<SparkItem>>();
    Future<void> reload() async {
      if (controller.isClosed) return;
      controller.add(await _loadSpark(myUid));
    }

    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[
      _likes.where('fromUid', isEqualTo: myUid).snapshots().listen((_) => reload()),
      _likes
          .where('toOwnerId', isEqualTo: myUid)
          .snapshots()
          .listen((_) => reload()),
      _matches
          .where('userIds', arrayContains: myUid)
          .snapshots()
          .listen((_) => reload()),
    ];
    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };
    reload();
    return controller.stream;
  }

  Future<List<SparkItem>> _loadSpark(String myUid) async {
    final matchSnap =
        await _matches.where('userIds', arrayContains: myUid).get();
    final matchedUids = <String>{};
    for (final doc in matchSnap.docs) {
      final ids = List<String>.from(doc.data()['userIds'] as List? ?? const []);
      for (final id in ids) {
        if (id != myUid) matchedUids.add(id);
      }
    }

    final sent = await _likes.where('fromUid', isEqualTo: myUid).get();
    final received = await _likes.where('toOwnerId', isEqualTo: myUid).get();
    final items = <SparkItem>[];
    final seen = <String>{};

    Future<void> add(String petId, SparkBucket bucket) async {
      if (seen.contains(petId)) return;
      seen.add(petId);
      final pet = await _pets.doc(petId).get();
      final profile = PetCodec.toDiscovery(pet.id, pet.data());
      if (profile == null) return;
      items.add(
        SparkItem(
          id: 'spark_${profile.id}',
          profile: profile,
          bucket: bucket,
        ),
      );
    }

    for (final uid in matchedUids) {
      await add(uid, SparkBucket.matched);
    }
    for (final doc in sent.docs) {
      final toPetId = doc.data()['toPetId'] as String? ?? '';
      if (toPetId.isEmpty || matchedUids.contains(toPetId)) continue;
      await add(toPetId, SparkBucket.sent);
    }
    for (final doc in received.docs) {
      final fromUid = doc.data()['fromUid'] as String? ?? '';
      if (fromUid.isEmpty || matchedUids.contains(fromUid)) continue;
      await add(fromUid, SparkBucket.received);
    }
    return items;
  }

  @override
  Stream<List<ChatThread>> watchThreads({required String myUid}) {
    final controller = StreamController<List<ChatThread>>();
    final matchSubs = <StreamSubscription<dynamic>>[];
    final detailSubs = <StreamSubscription<dynamic>>[];

    Future<void> emit(QuerySnapshot<Map<String, dynamic>> matchSnap) async {
      if (controller.isClosed) return;
      final threads = <ChatThread>[];
      for (final match in matchSnap.docs) {
        final thread = await _threadForMatch(match.id, match.data(), myUid);
        if (thread != null) threads.add(thread);
      }
      if (!controller.isClosed) controller.add(threads);
    }

    Future<void> bindDetails(QuerySnapshot<Map<String, dynamic>> snap) async {
      for (final sub in List<StreamSubscription<dynamic>>.from(detailSubs)) {
        await sub.cancel();
      }
      detailSubs.clear();
      for (final match in snap.docs) {
        detailSubs.add(
          _threads.doc(match.id).snapshots().listen((_) => emit(snap)),
        );
        detailSubs.add(
          _threads
              .doc(match.id)
              .collection(IdentityContract.messagesCollection)
              .snapshots()
              .listen((_) => emit(snap)),
        );
        detailSubs.add(
          _proposals
              .where('matchId', isEqualTo: match.id)
              .snapshots()
              .listen((_) => emit(snap)),
        );
      }
      await emit(snap);
    }

    controller
      ..onListen = () {
        matchSubs.add(
          _matches
              .where('userIds', arrayContains: myUid)
              .snapshots()
              .listen(bindDetails),
        );
      }
      ..onCancel = () async {
        for (final sub in [...matchSubs, ...detailSubs]) {
          await sub.cancel();
        }
      };
    return controller.stream;
  }

  Future<ChatThread?> _threadForMatch(
    String matchId,
    Map<String, dynamic> matchData,
    String myUid,
  ) async {
    final userIds = List<String>.from(matchData['userIds'] as List? ?? const []);
    final other = userIds.firstWhere((id) => id != myUid, orElse: () => myUid);
    final pet = await _pets.doc(other).get();
    final profile = PetCodec.toDiscovery(pet.id, pet.data());
    // Withdrawn / deleted counterpart: drop the room (no placeholder row).
    if (profile == null) return null;

    final msgSnap = await _threads
        .doc(matchId)
        .collection(IdentityContract.messagesCollection)
        .orderBy('createdAt')
        .get();
    final proposalSnap =
        await _proposals.where('matchId', isEqualTo: matchId).get();
    final receipts = <String, MeetupReceipt>{};
    final proposals = <String, MeetupProposal>{};
    for (final doc in proposalSnap.docs) {
      final data = doc.data();
      receipts[doc.id] = _receiptOf(data['status'] as String?);
      proposals[doc.id] = MeetupProposal(
        place: MeetupPlaceCopy.fromType(data['placeType'] as String?),
        placeDetail: '',
        timeLabel: data['timeSlot'] as String? ?? '',
        memo: '',
      );
    }

    final messages = <ChatMessage>[
      ChatMessage(
        id: 'sys_$matchId',
        text: AppCopy.chatSystemMatch,
        isMine: false,
        kind: ChatMessageKind.system,
      ),
      for (final doc in msgSnap.docs)
        _messageFrom(doc, myUid, receipts[doc.id], proposals[doc.id]),
    ];

    final threadSnap = await _threads.doc(matchId).get();
    DateTime? updatedAt;
    final updatedRaw = threadSnap.data()?['updatedAt'];
    if (updatedRaw is Timestamp) {
      updatedAt = updatedRaw.toDate();
    } else if (msgSnap.docs.isNotEmpty) {
      final created = msgSnap.docs.last.data()['createdAt'];
      if (created is Timestamp) updatedAt = created.toDate();
    }

    final lastUser = messages.lastWhere(
      (m) => m.kind != ChatMessageKind.system,
      orElse: () => messages.first,
    );
    final unread =
        lastUser.kind != ChatMessageKind.system && !lastUser.isMine;

    return ChatThread(
      id: matchId,
      profile: profile,
      messages: messages,
      updatedAt: updatedAt,
      unread: unread,
      participantIds: {...userIds},
    );
  }

  ChatMessage _messageFrom(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String myUid,
    MeetupReceipt? receipt,
    MeetupProposal? proposal,
  ) {
    final data = doc.data();
    final type = data['type'] as String? ?? 'text';
    final text = data['text'] as String? ?? '';
    final resolved = proposal == null
        ? null
        : MeetupProposal(
            place: proposal.place,
            placeDetail: proposal.placeDetail,
            timeLabel: proposal.timeLabel,
            memo: _memoFromText(text),
          );
    return ChatMessage(
      id: doc.id,
      text: text,
      isMine: data['senderId'] == myUid,
      kind: type == 'meet_proposal'
          ? ChatMessageKind.meetup
          : ChatMessageKind.text,
      receipt: type == 'meet_proposal'
          ? (receipt ?? MeetupReceipt.pending)
          : null,
      proposal: type == 'meet_proposal' ? resolved : null,
    );
  }

  String _memoFromText(String text) {
    final breakAt = text.indexOf('\n');
    if (breakAt < 0) return '';
    return text.substring(breakAt + 1).trim();
  }

  MeetupReceipt _receiptOf(String? status) {
    return switch (status) {
      'accepted' => MeetupReceipt.accepted,
      'counter' => MeetupReceipt.countered,
      'dismissed' => MeetupReceipt.ignored,
      _ => MeetupReceipt.pending,
    };
  }

  String _statusOf(MeetupReceipt receipt) {
    return switch (receipt) {
      MeetupReceipt.accepted => 'accepted',
      MeetupReceipt.countered => 'counter',
      MeetupReceipt.ignored => 'dismissed',
      MeetupReceipt.pending => 'pending',
    };
  }

  String _placeType(MeetupPlace place) {
    return switch (place) {
      MeetupPlace.park => 'park',
      MeetupPlace.petCafe => 'petCafe',
      MeetupPlace.other => 'other',
    };
  }

  String _meetupText(MeetupProposal proposal) => MeetupCopy.cardText(proposal);

  String _timeSlotOf(MeetupProposal proposal) {
    final extra = proposal.place == MeetupPlace.other
        ? proposal.placeDetail.trim()
        : '';
    final memo = proposal.memo.trim();
    final parts = [
      proposal.timeLabel,
      if (extra.isNotEmpty) extra,
      if (memo.isNotEmpty) memo,
    ];
    final joined = parts.join(' · ');
    if (joined.length <= 80) return joined;
    return joined.substring(0, 80);
  }

  @override
  Future<bool> sendLike({
    required String fromUid,
    required DiscoveryProfile to,
  }) async {
    final toPetId = to.id;
    final toOwnerId = to.id;
    final likeRef = _likes.doc(
      FirestoreIds.likeId(fromUid: fromUid, toPetId: toPetId),
    );
    final theirLike = await _likes
        .doc(FirestoreIds.likeId(fromUid: toOwnerId, toPetId: fromUid))
        .get();
    final matched = theirLike.exists;

    final batch = _db.batch();
    batch.set(likeRef, {
      'fromUid': fromUid,
      'toPetId': toPetId,
      'toOwnerId': toOwnerId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (matched) {
      final userIds = FirestoreIds.sortedUids(fromUid, toOwnerId);
      final matchId = FirestoreIds.matchId(fromUid, toOwnerId);
      batch.set(_matches.doc(matchId), {
        'userIds': userIds,
        'petIds': FirestoreIds.petIdsForUsers(userIds),
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_threads.doc(matchId), {
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return matched;
  }

  @override
  Future<void> sendText({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final msgRef = _threads
        .doc(matchId)
        .collection(IdentityContract.messagesCollection)
        .doc();
    final batch = _db.batch();
    batch.set(msgRef, {
      'senderId': senderId,
      'text': trimmed,
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_threads.doc(matchId), {
      'lastMessage': trimmed.length > 1000 ? trimmed.substring(0, 1000) : trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> sendMeetup({
    required String matchId,
    required String fromUid,
    required MeetupProposal proposal,
  }) async {
    final text = _meetupText(proposal);
    final id = _proposals.doc().id;
    final batch = _db.batch();
    batch.set(_proposals.doc(id), {
      'matchId': matchId,
      'fromUid': fromUid,
      'placeType': _placeType(proposal.place),
      'timeSlot': _timeSlotOf(proposal),
      'status': 'pending',
    });
    batch.set(
      _threads
          .doc(matchId)
          .collection(IdentityContract.messagesCollection)
          .doc(id),
      {
        'senderId': fromUid,
        'text': text,
        'type': 'meet_proposal',
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    batch.update(_threads.doc(matchId), {
      'lastMessage': text.length > 1000 ? text.substring(0, 1000) : text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> setMeetupStatus({
    required String proposalId,
    required MeetupReceipt receipt,
    MeetupProposal? counter,
  }) async {
    final updates = <String, dynamic>{
      'status': _statusOf(receipt),
    };
    if (receipt == MeetupReceipt.countered && counter != null) {
      updates['placeType'] = _placeType(counter.place);
      updates['timeSlot'] = _timeSlotOf(counter);
    }
    await _proposals.doc(proposalId).update(updates);
  }

  @override
  Future<void> upsertPet({
    required String uid,
    required ProfileDraft draft,
  }) async {
    // Merge so existing geohash/latlng survive profile edits.
    await _pets.doc(uid).set(
          PetCodec.toFirestore(uid: uid, draft: draft),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> updatePetLocation({
    required String uid,
    required ApproxLatLng point,
  }) async {
    await _pets.doc(uid).update(PetCodec.locationFields(point));
  }

  @override
  Future<ProfileDraft?> readPet(String uid) async {
    final snap = await _pets.doc(uid).get();
    if (!snap.exists) return null;
    return PetCodec.toDraft(snap.id, snap.data());
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await _blocks.doc(
      FirestoreIds.blockId(blockerId: blockerId, blockedId: blockedId),
    ).set({
      'blockerId': blockerId,
      'blockedId': blockedId,
    });
  }

  @override
  Future<void> reportTarget({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    await _reports.add({
      'reporterId': reporterId,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<Set<String>> watchBlockedIds({required String blockerId}) {
    return _blocks
        .where('blockerId', isEqualTo: blockerId)
        .snapshots()
        .map((snap) => {
              for (final doc in snap.docs)
                doc.data()['blockedId'] as String? ?? '',
            }..removeWhere((id) => id.isEmpty));
  }
}
