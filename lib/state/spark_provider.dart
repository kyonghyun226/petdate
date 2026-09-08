import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/spark.dart';
import 'package:petdate/state/session_provider.dart';

@immutable
class SparkState {
  const SparkState({this.items = const []});

  final List<SparkItem> items;

  List<SparkItem> of(SparkBucket bucket) =>
      [for (final item in items) if (item.bucket == bucket) item];

  SparkItem? byProfile(String profileId) {
    for (final item in items) {
      if (item.profile.id == profileId) return item;
    }
    return null;
  }
}

class SparkNotifier extends Notifier<SparkState> {
  @override
  SparkState build() {
    ref.watch(sessionLoggedInTickProvider);
    final received = [
      for (final p in MockCatalog.withinRadius())
        if (p.likedMe)
          SparkItem(
            id: 'spark_${p.id}',
            profile: p,
            bucket: SparkBucket.received,
          ),
    ];
    return SparkState(items: received);
  }

  /// Returns true when the like creates a match.
  bool like(DiscoveryProfile profile) {
    final existing = state.byProfile(profile.id);
    if (existing?.bucket == SparkBucket.matched) return false;

    if (existing?.bucket == SparkBucket.received || profile.likedMe) {
      _upsert(profile, SparkBucket.matched);
      return true;
    }
    _upsert(profile, SparkBucket.sent);
    return false;
  }

  void _upsert(DiscoveryProfile profile, SparkBucket bucket) {
    final next = [
      for (final item in state.items)
        if (item.profile.id != profile.id) item,
      SparkItem(
        id: 'spark_${profile.id}',
        profile: profile,
        bucket: bucket,
      ),
    ];
    state = SparkState(items: next);
  }
}

final sparkProvider = NotifierProvider<SparkNotifier, SparkState>(
  SparkNotifier.new,
);
