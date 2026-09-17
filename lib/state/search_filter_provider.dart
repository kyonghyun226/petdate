import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/state/profile_provider.dart';

/// Pet age bands for discovery search (inclusive ranges).
enum PetAgeBand {
  underOne,
  oneToThree,
  threeToSeven,
  overSeven,
}

@immutable
class SearchFilter {
  const SearchFilter({
    this.radiusKm = AppConstants.searchRadiusKm,
    this.petGenders = const {},
    this.petSizes = const {},
    this.petAgeBands = const {},
    this.tagKeys = const {},
    this.timeSlots = const {},
    this.ownerAgeBands = const {},
    this.ownerGenders = const {},
    this.dogExperiences = const {},
  });

  /// Preset distances shown on the filter screen (km).
  static const radiusOptionsKm = <double>[5, 10, 20, 40];

  final double radiusKm;
  final Set<PetGender> petGenders;
  final Set<PetSize> petSizes;
  final Set<PetAgeBand> petAgeBands;
  final Set<String> tagKeys;
  final Set<PreferredTimeSlot> timeSlots;
  final Set<OwnerAgeBand> ownerAgeBands;
  final Set<OwnerGender> ownerGenders;
  final Set<DogExperience> dogExperiences;

  static const empty = SearchFilter();

  bool get isActive =>
      radiusKm != AppConstants.searchRadiusKm ||
      petGenders.isNotEmpty ||
      petSizes.isNotEmpty ||
      petAgeBands.isNotEmpty ||
      tagKeys.isNotEmpty ||
      timeSlots.isNotEmpty ||
      ownerAgeBands.isNotEmpty ||
      ownerGenders.isNotEmpty ||
      dogExperiences.isNotEmpty;

  int get activeCount {
    var n = 0;
    if (radiusKm != AppConstants.searchRadiusKm) n++;
    if (petGenders.isNotEmpty) n++;
    if (petSizes.isNotEmpty) n++;
    if (petAgeBands.isNotEmpty) n++;
    if (tagKeys.isNotEmpty) n++;
    if (timeSlots.isNotEmpty) n++;
    if (ownerAgeBands.isNotEmpty) n++;
    if (ownerGenders.isNotEmpty) n++;
    if (dogExperiences.isNotEmpty) n++;
    return n;
  }

  /// [applyRadius] is false until the user has a location origin.
  bool matches(DiscoveryProfile profile, {bool applyRadius = true}) {
    if (applyRadius) {
      if (profile.distanceKm < 0) return false;
      if (profile.distanceKm > radiusKm) return false;
    }
    if (petGenders.isNotEmpty && !petGenders.contains(profile.gender)) {
      return false;
    }
    if (petSizes.isNotEmpty && !petSizes.contains(profile.size)) {
      return false;
    }
    if (petAgeBands.isNotEmpty &&
        !_ageMatches(profile.ageYears, petAgeBands)) {
      return false;
    }
    if (tagKeys.isNotEmpty &&
        !profile.tagKeys.any(tagKeys.contains)) {
      return false;
    }
    if (timeSlots.isNotEmpty &&
        !profile.preferredTimeSlots.any(timeSlots.contains)) {
      return false;
    }
    if (ownerAgeBands.isNotEmpty) {
      final band = profile.ownerAgeBand;
      if (band == null || !ownerAgeBands.contains(band)) return false;
    }
    if (ownerGenders.isNotEmpty) {
      final gender = profile.ownerGender;
      if (gender == null || !ownerGenders.contains(gender)) return false;
    }
    if (dogExperiences.isNotEmpty) {
      final exp = profile.dogExperience;
      if (exp == null || !dogExperiences.contains(exp)) return false;
    }
    return true;
  }

  static bool _ageMatches(int ageYears, Set<PetAgeBand> bands) {
    for (final band in bands) {
      final ok = switch (band) {
        PetAgeBand.underOne => ageYears < 1,
        PetAgeBand.oneToThree => ageYears >= 1 && ageYears < 3,
        PetAgeBand.threeToSeven => ageYears >= 3 && ageYears < 7,
        PetAgeBand.overSeven => ageYears >= 7,
      };
      if (ok) return true;
    }
    return false;
  }

  SearchFilter copyWith({
    double? radiusKm,
    Set<PetGender>? petGenders,
    Set<PetSize>? petSizes,
    Set<PetAgeBand>? petAgeBands,
    Set<String>? tagKeys,
    Set<PreferredTimeSlot>? timeSlots,
    Set<OwnerAgeBand>? ownerAgeBands,
    Set<OwnerGender>? ownerGenders,
    Set<DogExperience>? dogExperiences,
  }) {
    return SearchFilter(
      radiusKm: radiusKm ?? this.radiusKm,
      petGenders: petGenders ?? this.petGenders,
      petSizes: petSizes ?? this.petSizes,
      petAgeBands: petAgeBands ?? this.petAgeBands,
      tagKeys: tagKeys ?? this.tagKeys,
      timeSlots: timeSlots ?? this.timeSlots,
      ownerAgeBands: ownerAgeBands ?? this.ownerAgeBands,
      ownerGenders: ownerGenders ?? this.ownerGenders,
      dogExperiences: dogExperiences ?? this.dogExperiences,
    );
  }
}

class SearchFilterNotifier extends Notifier<SearchFilter> {
  @override
  SearchFilter build() => SearchFilter.empty;

  void replace(SearchFilter next) => state = next;

  void clear() => state = SearchFilter.empty;

  void setRadiusKm(double value) {
    state = state.copyWith(radiusKm: value);
  }

  void togglePetGender(PetGender value) {
    state = state.copyWith(petGenders: _toggle(state.petGenders, value));
  }

  void togglePetSize(PetSize value) {
    state = state.copyWith(petSizes: _toggle(state.petSizes, value));
  }

  void togglePetAgeBand(PetAgeBand value) {
    state = state.copyWith(petAgeBands: _toggle(state.petAgeBands, value));
  }

  void toggleTag(String key) {
    state = state.copyWith(tagKeys: _toggle(state.tagKeys, key));
  }

  void toggleTimeSlot(PreferredTimeSlot value) {
    state = state.copyWith(timeSlots: _toggle(state.timeSlots, value));
  }

  void toggleOwnerAgeBand(OwnerAgeBand value) {
    state = state.copyWith(ownerAgeBands: _toggle(state.ownerAgeBands, value));
  }

  void toggleOwnerGender(OwnerGender value) {
    state = state.copyWith(ownerGenders: _toggle(state.ownerGenders, value));
  }

  void toggleDogExperience(DogExperience value) {
    state =
        state.copyWith(dogExperiences: _toggle(state.dogExperiences, value));
  }

  static Set<T> _toggle<T>(Set<T> current, T value) {
    final next = {...current};
    if (!next.add(value)) next.remove(value);
    return next;
  }
}

final searchFilterProvider =
    NotifierProvider<SearchFilterNotifier, SearchFilter>(
  SearchFilterNotifier.new,
);
