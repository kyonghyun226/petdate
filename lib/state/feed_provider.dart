import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/data/backend_mode.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/data/social_providers.dart';
import 'package:petdate/location/geo.dart';
import 'package:petdate/location/location_providers.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/search_filter_provider.dart';
import 'package:petdate/state/session_provider.dart';

@immutable
class FeedState {
  const FeedState({
    this.catalog = const [],
    this.remaining = const [],
    this.passedIds = const {},
    this.actedIds = const {},
  });

  /// Full explore catalog (unfiltered by pass/like). Used by 멍스타.
  final List<DiscoveryProfile> catalog;
  final List<DiscoveryProfile> remaining;
  final Set<String> passedIds;
  final Set<String> actedIds;

  List<DiscoveryProfile> get visible => remaining;

  DiscoveryProfile? get current {
    final list = visible;
    return list.isEmpty ? null : list.first;
  }

  FeedState copyWith({
    List<DiscoveryProfile>? catalog,
    List<DiscoveryProfile>? remaining,
    Set<String>? passedIds,
    Set<String>? actedIds,
  }) {
    return FeedState(
      catalog: catalog ?? this.catalog,
      remaining: remaining ?? this.remaining,
      passedIds: passedIds ?? this.passedIds,
      actedIds: actedIds ?? this.actedIds,
    );
  }
}

class FeedNotifier extends Notifier<FeedState> {
  List<DiscoveryProfile> _rawCatalog = const [];
  Set<String> _blocked = {};

  @override
  FeedState build() {
    ref.watch(sessionLoggedInTickProvider);
    ref.listen(searchFilterProvider, (_, _) => _applyCatalog());
    ref.listen(myLocationProvider, (_, _) => _applyCatalog());
    final useMock = ref.watch(useMockDataProvider);
    if (useMock) {
      _rawCatalog = List<DiscoveryProfile>.of(MockCatalog.profiles);
      _blocked = {};
      final filter = ref.read(searchFilterProvider);
      final catalog = _withDistances(_rawCatalog);
      return FeedState(
        catalog: catalog,
        remaining: [
          for (final p in catalog)
            if (filter.matches(p)) p,
        ],
      );
    }

    final uid = ref.watch(sessionProvider.select((s) => s.uid));
    if (uid == null) {
      _rawCatalog = const [];
      _blocked = {};
      return const FeedState();
    }

    final sub = ref
        .read(socialRepositoryProvider)
        .watchExplore(myUid: uid, blockedIds: const {})
        .listen((pets) {
      _rawCatalog = pets;
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

  List<DiscoveryProfile> _withDistances(List<DiscoveryProfile> pets) {
    // Review-demo / MockCatalog already has baked-in distances — never
    // overwrite with GPS (demo pets have no latlng → would become unknown
    // and vanish from the radius filter).
    if (ref.read(useMockDataProvider)) return pets;

    final origin = ref.read(myLocationProvider);
    if (origin == null) return pets;
    return [
      for (final p in pets) _distanceFrom(origin, p),
    ];
  }

  DiscoveryProfile _distanceFrom(ApproxLatLng origin, DiscoveryProfile p) {
    if (!p.hasGeo) {
      return p.copyWith(distanceKm: DiscoveryProfile.unknownDistanceKm);
    }
    final km = Geo.distanceKm(
      origin,
      ApproxLatLng(p.latitude!, p.longitude!),
    );
    return p.copyWith(distanceKm: km);
  }

  void _applyCatalog() {
    final filter = ref.read(searchFilterProvider);
    final useMock = ref.read(useMockDataProvider);
    final origin = ref.read(myLocationProvider);
    // Mock distances are baked in; live needs GPS origin to enforce radius.
    final applyRadius = useMock || origin != null;
    final catalog = _withDistances(_rawCatalog);
    final liked = state.actedIds.difference(state.passedIds);
    final catalogById = {for (final p in catalog) p.id: p};
    final ordered = <DiscoveryProfile>[];
    final seen = <String>{};
    for (final p in state.remaining) {
      final fresh = catalogById[p.id];
      if (fresh == null ||
          liked.contains(p.id) ||
          _blocked.contains(p.id) ||
          !filter.matches(fresh, applyRadius: applyRadius)) {
        continue;
      }
      ordered.add(fresh);
      seen.add(p.id);
    }
    for (final p in catalog) {
      if (seen.contains(p.id) ||
          liked.contains(p.id) ||
          _blocked.contains(p.id) ||
          !filter.matches(p, applyRadius: applyRadius)) {
        continue;
      }
      if (state.passedIds.contains(p.id)) continue;
      ordered.add(p);
    }
    // Near → far when distances are known.
    if (applyRadius) {
      ordered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }
    state = state.copyWith(
      catalog: [
        for (final p in catalog)
          if (!_blocked.contains(p.id)) p,
      ],
      remaining: ordered,
    );
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
    final filter = ref.read(searchFilterProvider);
    final useMock = ref.read(useMockDataProvider);
    final applyRadius = useMock || ref.read(myLocationProvider) != null;
    final remainingIds = {for (final p in state.remaining) p.id};
    final next = [
      ...state.remaining,
      for (final p in state.catalog)
        if (!remainingIds.contains(p.id) &&
            filter.matches(p, applyRadius: applyRadius) &&
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
