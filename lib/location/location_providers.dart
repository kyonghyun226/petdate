import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/data/social_providers.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/location/geo.dart';
import 'package:petdate/location/location_coordinator.dart';
import 'package:petdate/location/location_prompt_store.dart';
import 'package:petdate/location/location_service.dart';
import 'package:petdate/push/push_providers.dart';
import 'package:petdate/state/session_provider.dart';

/// Current user's approximate origin for distance labels / radius filter.
class MyLocationNotifier extends Notifier<ApproxLatLng?> {
  @override
  ApproxLatLng? build() => null;

  void set(ApproxLatLng? value) => state = value;
}

final myLocationProvider =
    NotifierProvider<MyLocationNotifier, ApproxLatLng?>(MyLocationNotifier.new);

final locationPromptStoreProvider = Provider<LocationPromptStore>((ref) {
  return PrefsLocationPromptStore();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationService();
});

final locationCoordinatorProvider = Provider<LocationCoordinator>((ref) {
  final coordinator = LocationCoordinator(
    store: ref.watch(locationPromptStoreProvider),
    service: ref.watch(locationServiceProvider),
    hasAuth: () => IdentityRemote.isLiveAuthReady,
    onMain: () => ref.read(sessionProvider).phase == AppPhase.main,
    uid: () =>
        IdentityRemote.authUid ?? ref.read(sessionProvider).uid,
    persistLocation: ({required uid, required point}) {
      return ref.read(ownPetRepositoryProvider).updatePetLocation(
            uid: uid,
            point: point,
          );
    },
    navigatorKey: ref.watch(rootNavigatorKeyProvider),
    onLocationChanged: (point) {
      ref.read(myLocationProvider.notifier).set(point);
    },
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

@immutable
class LocationOfferSnapshot {
  const LocationOfferSnapshot({required this.shouldOfferEnableInSettings});

  final bool shouldOfferEnableInSettings;
}
