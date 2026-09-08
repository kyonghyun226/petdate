import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/data/backend_mode.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/data/social_providers.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';

enum SpeciesFilter { all, dog, cat }

@immutable
class FeedState {
  const FeedState({
    this.remaining = const [],
    this.passedIds = const {},
    this.actedIds = const {},
    this.speciesFilter = SpeciesFilter.all,
  });

  final List<DiscoveryProfile> remaining;
  final Set<String> passedIds;
  final Set<String> actedIds;
  final SpeciesFilter speciesFilter;

  List<DiscoveryProfile> get visible {
    return [
      for (final p in remaining)
        if (speciesFilter == SpeciesFilter.all ||
            (speciesFilter == SpeciesFilter.dog &&
                p.species == PetSpecies.dog) ||
            (speciesFilter == SpeciesFilter.cat &&
                p.species == PetSpecies.cat))
          p,
    ];
  }

  DiscoveryProfile? get current {
    final list = visible;
    return list.isEmpty ? null : list.first;
  }

  FeedState copyWith({
    List<DiscoveryProfile>? remaining,
    Set<String>? passedIds,
    Set<String>? actedIds,
    SpeciesFilter? speciesFilter,
  }) {
    return FeedState(
      remaining: remaining ?? this.remaining,
      passedIds: passedIds ?? this.passedIds,
      actedIds: actedIds ?? this.actedIds,
      speciesFilter: speciesFilter ?? this.speciesFilter,
    );
  }
}

class FeedNotifier extends Notifier<FeedState> {
  List<DiscoveryProfile> _catalog = const [];
  Set<String> _blocked = {};

  @override
  FeedState build() {
    ref.watch(sessionLoggedInTickProvider);
    final useMock = ref.watch(useMockDataProvider);
    if (useMock) {
      _catalog = MockCatalog.withinRadius();
      _blocked = {};
      return FeedState(remaining: _catalog);
    }

    final uid = ref.watch(sessionProvider.select((s) => s.uid));
    if (uid == null) {
      _catalog = const [];
      _blocked = {};
      return const FeedState();
    }

    final sub = ref
        .read(socialRepositoryProvider)
        .watchExplore(myUid: uid, blockedIds: const {})
        .listen((pets) {
      _catalog = pets;
      _applyCatalog();
    });
    final blockSub = ref
        .read(socialRepositoryProvider)
        .watchBlockedIds(blockerId: uid)
        .listen((ids) {
      _blocked = ids;
      _applyCatalog();
    });
    ref.onDispose(() {
      sub.cancel();
      blockSub.cancel();
    });
    return const FeedState();
  }

  void _applyCatalog() {
    final liked = state.actedIds.difference(state.passedIds);
    final catalogById = {for (final p in _catalog) p.id: p};
    final ordered = <DiscoveryProfile>[];
    final seen = <String>{};
    for (final p in state.remaining) {
      final fresh = catalogById[p.id];
      if (fresh == null || liked.contains(p.id) || _blocked.contains(p.id)) {
        continue;
      }
      ordered.add(fresh);
      seen.add(p.id);
    }
    for (final p in _catalog) {
      if (seen.contains(p.id) ||
          liked.contains(p.id) ||
          _blocked.contains(p.id)) {
        continue;
      }
      if (state.passedIds.contains(p.id)) continue;
      ordered.add(p);
    }
    state = state.copyWith(remaining: ordered);
  }

  void setSpeciesFilter(SpeciesFilter filter) {
    state = state.copyWith(speciesFilter: filter);
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
    final remainingIds = {for (final p in state.remaining) p.id};
    final next = [
      ...state.remaining,
      for (final p in _catalog)
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
