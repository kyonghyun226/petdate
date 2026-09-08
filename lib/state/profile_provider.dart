import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/state/session_provider.dart';

enum PetSpecies { dog, cat }

enum PetGender { male, female }

enum PetSize { small, medium, large }

enum AgeInputMode { age, birth }

@immutable
class MockPhoto {
  const MockPhoto({
    required this.id,
    required this.seed,
  });

  final String id;
  final int seed;
}

@immutable
class ProfileDraft {
  const ProfileDraft({
    this.step = 0,
    this.petName = '',
    this.species,
    this.breed = '',
    this.ageInputMode = AgeInputMode.age,
    this.ageYears,
    this.birthYear,
    this.birthMonth,
    this.gender,
    this.size,
    this.photos = const [],
    this.primaryPhotoId,
    this.tags = const {},
    this.preferredTimeSlots = const {},
    this.bio = '',
  });

  static const int lastStep = 3;
  static const int maxPhotos = 3;
  static const int minTags = AppConstants.minTags;
  static const int maxTags = AppConstants.maxTags;
  static const int minTimeSlots = AppConstants.minTimeSlots;
  static const int maxTimeSlots = AppConstants.maxTimeSlots;

  final int step;
  final String petName;
  final PetSpecies? species;
  final String breed;
  final AgeInputMode ageInputMode;
  final int? ageYears;
  final int? birthYear;
  final int? birthMonth;
  final PetGender? gender;
  final PetSize? size;
  final List<MockPhoto> photos;
  final String? primaryPhotoId;
  final Set<String> tags;
  final Set<PreferredTimeSlot> preferredTimeSlots;
  final String bio;

  String get displayName =>
      petName.trim().isEmpty ? AppCopy.fallbackPetName : petName.trim();

  int? get displayAgeYears {
    if (ageInputMode == AgeInputMode.age) return ageYears;
    if (birthYear == null) return null;
    final now = DateTime.now();
    var years = now.year - birthYear!;
    if (birthMonth != null && now.month < birthMonth!) years -= 1;
    return years < 0 ? 0 : years;
  }

  int get primaryPhotoSeed {
    if (photos.isEmpty) return 0;
    final primary = photos.where((p) => p.id == primaryPhotoId);
    return (primary.isEmpty ? photos.first : primary.first).seed;
  }

  bool get hasAgeOrBirth {
    if (ageInputMode == AgeInputMode.age) {
      return ageYears != null && ageYears! >= 0;
    }
    return birthYear != null && birthMonth != null;
  }

  bool get p01Valid =>
      petName.trim().isNotEmpty &&
      species != null &&
      breed.trim().isNotEmpty &&
      hasAgeOrBirth &&
      gender != null &&
      size != null;

  bool get p02Valid => photos.isNotEmpty;

  bool get p03TagsValid => tags.length >= minTags && tags.length <= maxTags;

  bool get p03TimesValid =>
      preferredTimeSlots.length >= minTimeSlots &&
      preferredTimeSlots.length <= maxTimeSlots;

  bool get p03Valid => p03TagsValid && p03TimesValid;

  bool get p04Valid => bio.length <= AppCopy.bioMax;

  bool get currentStepValid => switch (step) {
        0 => p01Valid,
        1 => p02Valid,
        2 => p03Valid,
        3 => p04Valid,
        _ => false,
      };

  ProfileDraft copyWith({
    int? step,
    String? petName,
    PetSpecies? species,
    String? breed,
    AgeInputMode? ageInputMode,
    int? ageYears,
    bool clearAgeYears = false,
    int? birthYear,
    bool clearBirthYear = false,
    int? birthMonth,
    bool clearBirthMonth = false,
    PetGender? gender,
    PetSize? size,
    List<MockPhoto>? photos,
    String? primaryPhotoId,
    bool clearPrimaryPhotoId = false,
    Set<String>? tags,
    Set<PreferredTimeSlot>? preferredTimeSlots,
    String? bio,
  }) {
    return ProfileDraft(
      step: step ?? this.step,
      petName: petName ?? this.petName,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      ageInputMode: ageInputMode ?? this.ageInputMode,
      ageYears: clearAgeYears ? null : (ageYears ?? this.ageYears),
      birthYear: clearBirthYear ? null : (birthYear ?? this.birthYear),
      birthMonth: clearBirthMonth ? null : (birthMonth ?? this.birthMonth),
      gender: gender ?? this.gender,
      size: size ?? this.size,
      photos: photos ?? this.photos,
      primaryPhotoId:
          clearPrimaryPhotoId ? null : (primaryPhotoId ?? this.primaryPhotoId),
      tags: tags ?? this.tags,
      preferredTimeSlots: preferredTimeSlots ?? this.preferredTimeSlots,
      bio: bio ?? this.bio,
    );
  }
}

class ProfileDraftNotifier extends Notifier<ProfileDraft> {
  int _photoSeq = 0;

  @override
  ProfileDraft build() {
    ref.watch(sessionLoggedInTickProvider);
    _photoSeq = 0;
    return const ProfileDraft();
  }

  void reset() {
    _photoSeq = 0;
    state = const ProfileDraft();
  }

  /// Restore a completed pet card (returning Auth session).
  void hydrate(ProfileDraft draft) {
    state = draft;
    _photoSeq = draft.photos.length;
  }

  void goTo(int step) {
    state = state.copyWith(step: step);
  }

  bool tryNext() {
    if (!state.currentStepValid) return false;
    if (state.step >= ProfileDraft.lastStep) return true;
    state = state.copyWith(step: state.step + 1);
    return true;
  }

  bool tryBack() {
    if (state.step <= 0) return false;
    state = state.copyWith(step: state.step - 1);
    return true;
  }

  void setPetName(String value) => state = state.copyWith(petName: value);

  void setSpecies(PetSpecies value) => state = state.copyWith(species: value);

  void setBreed(String value) => state = state.copyWith(breed: value);

  void setAgeInputMode(AgeInputMode mode) {
    state = state.copyWith(ageInputMode: mode);
  }

  void setAgeYears(int? years) {
    state = state.copyWith(
      ageYears: years,
      clearAgeYears: years == null,
    );
  }

  void setBirth({int? year, int? month}) {
    state = state.copyWith(
      birthYear: year,
      clearBirthYear: year == null,
      birthMonth: month,
      clearBirthMonth: month == null,
    );
  }

  void setGender(PetGender value) => state = state.copyWith(gender: value);

  void setSize(PetSize value) => state = state.copyWith(size: value);

  void addMockPhoto() {
    if (state.photos.length >= ProfileDraft.maxPhotos) return;
    final seq = _photoSeq++;
    final photo = MockPhoto(id: 'photo_$seq', seed: seq);
    final photos = [...state.photos, photo];
    state = state.copyWith(
      photos: photos,
      primaryPhotoId: state.primaryPhotoId ?? photo.id,
    );
  }

  void removePhoto(String id) {
    final photos = state.photos.where((p) => p.id != id).toList();
    var primary = state.primaryPhotoId;
    if (primary == id) {
      primary = photos.isEmpty ? null : photos.first.id;
    }
    state = state.copyWith(
      photos: photos,
      primaryPhotoId: primary,
      clearPrimaryPhotoId: primary == null,
    );
  }

  void setPrimaryPhoto(String id) {
    state = state.copyWith(primaryPhotoId: id);
  }

  void movePhoto(int from, int to) {
    if (from == to) return;
    if (from < 0 ||
        to < 0 ||
        from >= state.photos.length ||
        to >= state.photos.length) {
      return;
    }
    final photos = [...state.photos];
    final item = photos.removeAt(from);
    photos.insert(to, item);
    state = state.copyWith(photos: photos);
  }

  void toggleTag(String tagKey) {
    final next = {...state.tags};
    if (next.contains(tagKey)) {
      next.remove(tagKey);
    } else if (next.length < ProfileDraft.maxTags) {
      next.add(tagKey);
    }
    state = state.copyWith(tags: next);
  }

  void toggleTimeSlot(PreferredTimeSlot slot) {
    final next = {...state.preferredTimeSlots};
    if (next.contains(slot)) {
      next.remove(slot);
    } else if (next.length < ProfileDraft.maxTimeSlots) {
      next.add(slot);
    }
    state = state.copyWith(preferredTimeSlots: next);
  }

  void setBio(String value) {
    if (value.length > AppCopy.bioMax) {
      value = value.substring(0, AppCopy.bioMax);
    }
    state = state.copyWith(bio: value);
  }
}

final profileDraftProvider =
    NotifierProvider<ProfileDraftNotifier, ProfileDraft>(
  ProfileDraftNotifier.new,
);

