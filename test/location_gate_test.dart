import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/location/location_permission_gate.dart';
import 'package:petdate/location/location_prompt_store.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/search_filter_provider.dart';

void main() {
  test('Auth 없으면 위치 게이트는 no-op', () {
    const gate = LocationPermissionGate(
      hasAuth: false,
      onMain: true,
      alreadyAsked: false,
    );
    expect(gate.canShowPreprompt, isFalse);
  });

  test('메인 진입 전에는 묻지 않음', () {
    const gate = LocationPermissionGate(
      hasAuth: true,
      onMain: false,
      alreadyAsked: false,
    );
    expect(gate.canShowPreprompt, isFalse);
  });

  test('이미 물었으면 재요청 스팸 금지', () {
    const gate = LocationPermissionGate(
      hasAuth: true,
      onMain: true,
      alreadyAsked: true,
    );
    expect(gate.canShowPreprompt, isFalse);
  });

  test('메인 + Auth + 미요청일 때만 프리프롬프트', () {
    const gate = LocationPermissionGate(
      hasAuth: true,
      onMain: true,
      alreadyAsked: false,
    );
    expect(gate.canShowPreprompt, isTrue);
    expect(gate.canRequestOsPermission, isTrue);
  });

  test('거절 뒤에만 Y01 위치 켜기', () {
    final store = InMemoryLocationPromptStore();
    expect(store.shouldOfferEnableInSettings, isFalse);
    store.markDeclinedPreprompt();
    expect(store.shouldOfferEnableInSettings, isTrue);
    store.markGranted();
    expect(store.shouldOfferEnableInSettings, isFalse);
    store.markOsDenied();
    expect(store.shouldOfferEnableInSettings, isTrue);
  });

  test('radius filter skips unknown distance when applying radius', () {
    const far = DiscoveryProfile(
      id: 'a',
      name: 'A',
      ageYears: 2,
      distanceKm: DiscoveryProfile.unknownDistanceKm,
      breed: '믹스',
      species: PetSpecies.dog,
      gender: PetGender.male,
      size: PetSize.small,
      tagKeys: [],
      bio: '',
      photoSeeds: [1],
      preferredTimeSlots: [],
    );
    const filter = SearchFilter(radiusKm: 10);
    expect(filter.matches(far), isFalse);
    expect(filter.matches(far, applyRadius: false), isTrue);
  });

  test('location copy is walk/friend, not dating', () {
    final bundle = [
      AppCopy.locationPrepromptTitle,
      AppCopy.locationPrepromptBody,
      AppCopy.locationPrepromptAllow,
      AppCopy.locationPrepromptDeny,
      AppCopy.settingsLocation,
      AppCopy.settingsLocationHint,
    ].join(' ');
    expect(bundle, contains('근처'));
    expect(bundle, isNot(contains('연애')));
    expect(bundle, isNot(contains('데이트')));
  });

  test('formatPetDistance unknown is em dash', () {
    expect(formatPetDistance(DiscoveryProfile.unknownDistanceKm), '—');
  });
}
