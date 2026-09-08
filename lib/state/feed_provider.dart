import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/session_provider.dart';

@immutable
class FeedState {
  const FeedState({
    this.remaining = const [],
    this.passedIds = const {},
    this.actedIds = const {},
  });

  final List<DiscoveryProfile> remaining;
  final Set<String> passedIds;
  final Set<String> actedIds;

  DiscoveryProfile? get current => remaining.isEmpty ? null : remaining.first;

  FeedState copyWith({
    List<DiscoveryProfile>? remaining,
    Set<String>? passedIds,
    Set<String>? actedIds,
  }) {
    return FeedState(
      remaining: remaining ?? this.remaining,
      passedIds: passedIds ?? this.passedIds,
      actedIds: actedIds ?? this.actedIds,
    );
  }
}

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() {
    ref.watch(sessionLoggedInTickProvider);
    return FeedState(remaining: MockCatalog.withinRadius());
  }

  void pass() {
    final current = state.current;
    if (current == null) return;
    _dismiss(current.id, passed: true);
  }

  void dismiss(String profileId, {bool passed = false}) {
    _dismiss(profileId, passed: passed);
  }

  void _dismiss(String profileId, {required bool passed}) {
    final remaining = [
      for (final p in state.remaining)
        if (p.id != profileId) p,
    ];
    state = state.copyWith(
      remaining: remaining,
      passedIds: passed ? {...state.passedIds, profileId} : state.passedIds,
      actedIds: {...state.actedIds, profileId},
    );
  }

  /// Restores passed (not liked/matched) profiles into the stack.
  void refresh() {
    final catalog = MockCatalog.withinRadius();
    final remainingIds = {for (final p in state.remaining) p.id};
    final next = [
      ...state.remaining,
      for (final p in catalog)
        if (!remainingIds.contains(p.id) &&
            (state.passedIds.contains(p.id) || !state.actedIds.contains(p.id)))
          p,
    ];
    final restoredPass = {
      for (final id in state.passedIds)
        if (next.every((p) => p.id != id)) id,
    };
    state = state.copyWith(
      remaining: next,
      passedIds: restoredPass,
    );
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);
