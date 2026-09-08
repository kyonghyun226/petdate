import 'dart:async';

import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/data/social_repository.dart';
import 'package:petdate/firebase/firestore_ids.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/like_match.dart';
import 'package:petdate/models/spark.dart';
import 'package:petdate/state/profile_provider.dart';

/// In-memory social graph for tests and hosts without Firebase Auth.
class MockSocialRepository implements SocialRepository {
  MockSocialRepository({List<DiscoveryProfile>? catalog})
      : _catalog = List<DiscoveryProfile>.from(
          catalog ?? MockCatalog.withinRadius(),
        );

  final List<DiscoveryProfile> _catalog;
  final Map<String, LikeRecord> _likes = {};
  final Map<String, MatchRecord> _matches = {};
  final Map<String, ChatThread> _threads = {};
  final Map<String, MeetupReceipt> _proposalStatus = {};
  final Set<String> _blocked = {};
  final List<Map<String, String>> reports = [];
  final Map<String, ProfileDraft> _pets = {};

  int _msgSeq = 0;

  final _explore = StreamController<List<DiscoveryProfile>>.broadcast();
  final _spark = StreamController<List<SparkItem>>.broadcast();
  final _threadsCtrl = StreamController<List<ChatThread>>.broadcast();
  final _blocks = StreamController<Set<String>>.broadcast();

  void dispose() {
    _explore.close();
    _spark.close();
    _threadsCtrl.close();
    _blocks.close();
  }

  List<LikeRecord> get likes => _likes.values.toList();
  List<MatchRecord> get matches => _matches.values.toList();

  void _emitExplore(String myUid, Set<String> blockedIds) {
    if (_explore.isClosed) return;
    _explore.add([
      for (final p in _catalog)
        if (p.id != myUid && !blockedIds.contains(p.id)) p,
    ]);
  }

  List<SparkItem> _sparkItems(String myUid) {
    final matchedUids = {
      for (final m in _matches.values) m.otherUid(myUid),
    };
    final items = <SparkItem>[];
    for (final like in _likes.values) {
      if (like.fromUid == myUid) {
        final profile = _profile(like.toPetId);
        if (profile == null) continue;
        items.add(
          SparkItem(
            id: 'spark_${profile.id}',
            profile: profile,
            bucket: matchedUids.contains(profile.id)
                ? SparkBucket.matched
                : SparkBucket.sent,
          ),
        );
      } else if (like.toOwnerId == myUid) {
        final profile = _profile(like.fromUid);
        if (profile == null) continue;
        if (matchedUids.contains(profile.id)) continue;
        items.add(
          SparkItem(
            id: 'spark_${profile.id}',
            profile: profile,
            bucket: SparkBucket.received,
          ),
        );
      }
    }
    for (final p in _catalog) {
      if (!p.likedMe) continue;
      if (items.any((s) => s.profile.id == p.id)) continue;
      items.add(
        SparkItem(
          id: 'spark_${p.id}',
          profile: p,
          bucket: matchedUids.contains(p.id)
              ? SparkBucket.matched
              : SparkBucket.received,
        ),
      );
    }
    return [
      for (final item in items)
        if (!_blocked.contains(item.profile.id)) item,
    ];
  }

  DiscoveryProfile? _profile(String id) {
    for (final p in _catalog) {
      if (p.id == id) return p;
    }
    return MockCatalog.byId(id);
  }

  void _emitSpark(String myUid) {
    if (_spark.isClosed) return;
    _spark.add(_sparkItems(myUid));
  }

  void _emitThreads() {
    if (_threadsCtrl.isClosed) return;
    _threadsCtrl.add(_threads.values.toList());
  }

  ChatThread _ensureThread(String myUid, DiscoveryProfile profile) {
    final id = FirestoreIds.matchId(myUid, profile.id);
    final existing = _threads[id];
    if (existing != null) return existing;
    final thread = ChatThread(
      id: id,
      profile: profile,
      messages: [
        ChatMessage(
          id: 'sys_$id',
          text: AppCopy.chatSystemMatch,
          isMine: false,
          kind: ChatMessageKind.system,
        ),
      ],
    );
    _threads[id] = thread;
    return thread;
  }

  @override
  Stream<List<DiscoveryProfile>> watchExplore({
    required String myUid,
    required Set<String> blockedIds,
  }) {
    return Stream<List<DiscoveryProfile>>.multi((listener) {
      _emitExplore(myUid, blockedIds);
      listener.add([
        for (final p in _catalog)
          if (p.id != myUid && !blockedIds.contains(p.id)) p,
      ]);
      final sub = _explore.stream.listen(listener.add);
      listener.onCancel = sub.cancel;
    });
  }

  @override
  Stream<List<SparkItem>> watchSpark({required String myUid}) {
    return Stream<List<SparkItem>>.multi((listener) {
      listener.add(_sparkItems(myUid));
      final sub = _spark.stream.listen(listener.add);
      listener.onCancel = sub.cancel;
    });
  }

  @override
  Stream<List<ChatThread>> watchThreads({required String myUid}) {
    return Stream<List<ChatThread>>.multi((listener) {
      listener.add(_threads.values.toList());
      final sub = _threadsCtrl.stream.listen(listener.add);
      listener.onCancel = sub.cancel;
    });
  }

  @override
  Future<bool> sendLike({
    required String fromUid,
    required DiscoveryProfile to,
  }) async {
    final toOwnerId = to.id;
    final id = FirestoreIds.likeId(fromUid: fromUid, toPetId: to.id);
    _likes[id] = LikeRecord(
      id: id,
      fromUid: fromUid,
      toPetId: to.id,
      toOwnerId: toOwnerId,
    );
    final reciprocalId = FirestoreIds.likeId(
      fromUid: toOwnerId,
      toPetId: fromUid,
    );
    final matched = _likes.containsKey(reciprocalId) || to.likedMe;
    if (matched) {
      final userIds = FirestoreIds.sortedUids(fromUid, toOwnerId);
      final matchId = FirestoreIds.matchId(fromUid, toOwnerId);
      _matches[matchId] = MatchRecord(
        id: matchId,
        userIds: userIds,
        petIds: FirestoreIds.petIdsForUsers(userIds),
      );
      _ensureThread(fromUid, to);
    }
    _emitSpark(fromUid);
    _emitThreads();
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
    final thread = _threads[matchId];
    if (thread == null) return;
    _threads[matchId] = thread.copyWith(
      messages: [
        ...thread.messages,
        ChatMessage(
          id: 'msg_${_msgSeq++}',
          text: trimmed,
          isMine: true,
        ),
      ],
    );
    _emitThreads();
  }

  @override
  Future<void> sendMeetup({
    required String matchId,
    required String fromUid,
    required MeetupProposal proposal,
  }) async {
    final thread = _threads[matchId];
    if (thread == null) return;
    final place = MeetupPlaceCopy.label(proposal.place);
    final detail = proposal.place == MeetupPlace.other &&
            proposal.placeDetail.trim().isNotEmpty
        ? '${proposal.placeDetail.trim()} · $place'
        : place;
    final memo = proposal.memo.trim();
    final text = memo.isEmpty
        ? '만남 제안 · $detail · ${proposal.timeLabel}'
        : '만남 제안 · $detail · ${proposal.timeLabel}\n$memo';
    final id = 'prop_${_msgSeq++}';
    _proposalStatus[id] = MeetupReceipt.pending;
    _threads[matchId] = thread.copyWith(
      messages: [
        ...thread.messages,
        ChatMessage(
          id: id,
          text: text,
          isMine: true,
          kind: ChatMessageKind.meetup,
          receipt: MeetupReceipt.pending,
        ),
      ],
    );
    _emitThreads();
  }

  @override
  Future<void> setMeetupStatus({
    required String proposalId,
    required MeetupReceipt receipt,
    MeetupProposal? counter,
  }) async {
    _proposalStatus[proposalId] = receipt;
    for (final entry in _threads.entries) {
      final thread = entry.value;
      if (thread.messages.every((m) => m.id != proposalId)) continue;
      _threads[entry.key] = thread.copyWith(
        messages: [
          for (final m in thread.messages)
            if (m.id == proposalId) m.copyWith(receipt: receipt) else m,
        ],
      );
    }
    _emitThreads();
  }

  @override
  Future<void> upsertPet({
    required String uid,
    required ProfileDraft draft,
  }) async {
    _pets[uid] = draft;
  }

  @override
  Future<ProfileDraft?> readPet(String uid) async => _pets[uid];

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _blocked.add(blockedId);
    if (!_blocks.isClosed) _blocks.add(Set<String>.from(_blocked));
  }

  @override
  Future<void> reportTarget({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    reports.add({
      'reporterId': reporterId,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
    });
  }

  @override
  Stream<Set<String>> watchBlockedIds({required String blockerId}) {
    return Stream<Set<String>>.multi((listener) {
      listener.add(Set<String>.from(_blocked));
      final sub = _blocks.stream.listen(listener.add);
      listener.onCancel = sub.cancel;
    });
  }
}
