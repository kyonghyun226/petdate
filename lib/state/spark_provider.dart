import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/data/backend_mode.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/data/social_providers.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/spark.dart';
import 'package:petdate/state/session_provider.dart';

@immutable
class SparkState {
  const SparkState({this.items = const [], this.blockedIds = const {}});

  final List<SparkItem> items;
  final Set<String> blockedIds;

  List<SparkItem> of(SparkBucket bucket) => [
    for (final item in items)
      if (item.bucket == bucket && !blockedIds.contains(item.profile.id)) item,
  ];

  int get unseenReceivedCount => [
    for (final item in of(SparkBucket.received))
      if (!item.seen) item,
  ].length;

  SparkItem? byProfile(String profileId) {
    for (final item in items) {
      if (item.profile.id == profileId) return item;
    }
    return null;
  }

  SparkState copyWith({List<SparkItem>? items, Set<String>? blockedIds}) {
    return SparkState(
      items: items ?? this.items,
      blockedIds: blockedIds ?? this.blockedIds,
    );
  }
}

class SparkNotifier extends Notifier<SparkState> {
  @override
  SparkState build() {
    ref.watch(sessionLoggedInTickProvider);
    if (ref.watch(useMockDataProvider)) {
      return SparkState(
        blockedIds: {MockCatalog.blocked.id},
        items: _mockItems(DateTime.now()),
      );
    }

    final uid = ref.watch(sessionProvider.select((s) => s.uid));
    if (uid == null) return const SparkState();
    final repo = ref.read(socialRepositoryProvider);
    final sparkSub = repo.watchSpark(myUid: uid).listen(_applyRemote);
    final blockSub = repo.watchBlockedIds(blockerId: uid).listen((ids) {
      state = state.copyWith(blockedIds: ids);
    });
    ref.onDispose(() {
      sparkSub.cancel();
      blockSub.cancel();
    });
    return const SparkState();
  }

  /// Optimistic local update. Live likes also go through [SocialRepository.sendLike].
  bool like(DiscoveryProfile profile) {
    if (state.blockedIds.contains(profile.id)) return false;
    final existing = state.byProfile(profile.id);
    if (existing?.bucket == SparkBucket.matched) return false;

    if (existing?.bucket == SparkBucket.received || profile.likedMe) {
      _upsert(profile, SparkBucket.matched);
      return true;
    }
    _upsert(profile, SparkBucket.sent);
    return false;
  }

  void markReceivedSeen() {
    var changed = false;
    final next = <SparkItem>[];
    for (final item in state.items) {
      final visibleReceived =
          item.bucket == SparkBucket.received &&
          !item.seen &&
          !state.blockedIds.contains(item.profile.id);
      if (visibleReceived) {
        next.add(item.copyWith(seen: true));
        changed = true;
      } else {
        next.add(item);
      }
    }
    if (changed) state = state.copyWith(items: next);
  }

  void block(String profileId) {
    state = state.copyWith(blockedIds: {...state.blockedIds, profileId});
  }

  /// Test helper to drive empty / badge states without real data.
  void replaceForTest({List<SparkItem>? items, Set<String>? blockedIds}) {
    state = SparkState(
      items: items ?? state.items,
      blockedIds: blockedIds ?? state.blockedIds,
    );
  }

  void _applyRemote(List<SparkItem> items) {
    final prev = {for (final item in state.items) item.profile.id: item};
    state = state.copyWith(
      items: [
        for (final item in items)
          item.copyWith(
            seen:
                prev[item.profile.id]?.seen ??
                item.bucket != SparkBucket.received,
            createdAt: prev[item.profile.id]?.createdAt ?? item.createdAt,
          ),
      ],
    );
  }

  void _upsert(DiscoveryProfile profile, SparkBucket bucket) {
    final existing = state.byProfile(profile.id);
    final next = [
      for (final item in state.items)
        if (item.profile.id != profile.id) item,
      SparkItem(
        id: 'spark_${profile.id}',
        profile: profile,
        bucket: bucket,
        createdAt: existing?.createdAt ?? DateTime.now(),
        seen: true,
      ),
    ];
    state = state.copyWith(items: next);
  }
}

List<SparkItem> _mockItems(DateTime now) {
  DiscoveryProfile must(String id) {
    final profile = MockCatalog.byId(id);
    if (profile == null) {
      throw StateError('missing mock profile $id');
    }
    return profile;
  }

  return [
    SparkItem(
      id: 'spark_kong',
      profile: must('kong'),
      bucket: SparkBucket.received,
      seen: false,
      createdAt: now.subtract(const Duration(minutes: 8)),
    ),
    SparkItem(
      id: 'spark_bam',
      profile: must('bam'),
      bucket: SparkBucket.received,
      seen: false,
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    SparkItem(
      id: 'spark_nuri',
      profile: MockCatalog.blocked,
      bucket: SparkBucket.received,
      seen: false,
      createdAt: now.subtract(const Duration(minutes: 3)),
    ),
    SparkItem(
      id: 'spark_bori',
      profile: must('bori'),
      bucket: SparkBucket.sent,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    SparkItem(
      id: 'spark_dal',
      profile: must('dal'),
      bucket: SparkBucket.matched,
      createdAt: now.subtract(const Duration(days: 3)),
    ),
  ];
}

final sparkProvider = NotifierProvider<SparkNotifier, SparkState>(
  SparkNotifier.new,
);
