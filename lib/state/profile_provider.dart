import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/media/gallery_photo_picker.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/state/session_provider.dart';

enum PetSpecies { dog }

enum PetGender { male, female }

enum PetSize { small, medium, large }

enum AgeInputMode { age, birth }

/// Owner age band stored on `users/{uid}.ownerAgeBand`.
enum OwnerAgeBand { twenties, thirties, forties, fiftiesPlus }

/// Owner gender stored on `users/{uid}.ownerGender`.
enum OwnerGender { male, female }

/// How long the owner has raised dogs — `users/{uid}.dogExperience`.
enum DogExperience {
  firstTime,
  underOneYear,
  oneToThree,
  threeToFive,
  overFive,
}

@immutable
class MockPhoto {
  const MockPhoto({
    required this.id,
    required this.seed,
    this.localPath,
    this.bytes,
    this.storagePath,
    this.remoteUrl,
  });

  final String id;
  final int seed;

  /// Local gallery file path (or web blob URL). Optional metadata for upload.
  final String? localPath;

  /// Decoded image bytes for in-app preview / upload.
  final Uint8List? bytes;

  /// Firebase Storage object path, e.g. `pets/{uid}/photo_0.jpg`.
  final String? storagePath;

  /// HTTPS download URL for cold-start display.
  final String? remoteUrl;

  bool get hasLocalImage => bytes != null && bytes!.isNotEmpty;

  bool get hasRemoteImage => remoteUrl != null && remoteUrl!.isNotEmpty;

  bool get hasDisplayImage => hasLocalImage || hasRemoteImage;

  MockPhoto copyWith({
    String? id,
    int? seed,
    String? localPath,
    Uint8List? bytes,
    String? storagePath,
    String? remoteUrl,
    bool clearLocalPath = false,
    bool clearBytes = false,
    bool clearStoragePath = false,
    bool clearRemoteUrl = false,
  }) {
    return MockPhoto(
      id: id ?? this.id,
      seed: seed ?? this.seed,
      localPath: clearLocalPath ? null : (localPath ?? this.localPath),
      bytes: clearBytes ? null : (bytes ?? this.bytes),
      storagePath: clearStoragePath ? null : (storagePath ?? this.storagePath),
      remoteUrl: clearRemoteUrl ? null : (remoteUrl ?? this.remoteUrl),
    );
  }
}

@immutable
class ProfileDraft {
  const ProfileDraft({
    this.step = 0,
    this.ownerAgeBand,
    this.ownerGender,
    this.dogExperience,
    this.petName = '',
    this.species = PetSpecies.dog,
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

  static const int stepCount = 5;
  static const int lastStep = 4;
  static const int maxPhotos = 3;
  static const int minTags = AppConstants.minTags;
  static const int maxTags = AppConstants.maxTags;
  static const int minTimeSlots = AppConstants.minTimeSlots;
  static const int maxTimeSlots = AppConstants.maxTimeSlots;

  final int step;
  final OwnerAgeBand? ownerAgeBand;
  final OwnerGender? ownerGender;
  final DogExperience? dogExperience;
  final String petName;
  final PetSpecies species;
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

  MockPhoto? get primaryPhoto {
    if (photos.isEmpty) return null;
    final primary = photos.where((p) => p.id == primaryPhotoId);
    return primary.isEmpty ? photos.first : primary.first;
  }

  int get primaryPhotoSeed => primaryPhoto?.seed ?? 0;

  bool get hasAgeOrBirth {
    if (ageInputMode == AgeInputMode.age) {
      return ageYears != null && ageYears! >= 0;
    }
    return birthYear != null && birthMonth != null;
  }

  bool get p00Valid =>
      ownerAgeBand != null && ownerGender != null && dogExperience != null;

  bool get p01Valid =>
      petName.trim().isNotEmpty &&
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
        0 => p00Valid,
        1 => p01Valid,
        2 => p02Valid,
        3 => p03Valid,
        4 => p04Valid,
        _ => false,
      };

  ProfileDraft copyWith({
    int? step,
    OwnerAgeBand? ownerAgeBand,
    OwnerGender? ownerGender,
    DogExperience? dogExperience,
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
      ownerAgeBand: ownerAgeBand ?? this.ownerAgeBand,
      ownerGender: ownerGender ?? this.ownerGender,
      dogExperience: dogExperience ?? this.dogExperience,
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
    // Clear only on logout. Watching the tick would rebuild (and wipe) after
    // splash hydrates a returning session when isLoggedIn flips to true.
    ref.listen<int>(sessionLoggedInTickProvider, (previous, next) {
      if (next == 0) {
        _photoSeq = 0;
        state = const ProfileDraft();
      }
    });
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

  void setOwnerAgeBand(OwnerAgeBand value) =>
      state = state.copyWith(ownerAgeBand: value);

  void setOwnerGender(OwnerGender value) =>
      state = state.copyWith(ownerGender: value);

  void setDogExperience(DogExperience value) =>
      state = state.copyWith(dogExperience: value);

  void setPetName(String value) => state = state.copyWith(petName: value);

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

  /// Opens the gallery via [picker] and appends the chosen photo.
  Future<void> addPhotoFromGallery(GalleryPhotoPicker picker) async {
    if (state.photos.length >= ProfileDraft.maxPhotos) return;
    final picked = await picker.pickFromGallery();
    if (picked == null) return;
    final seq = _photoSeq++;
    final photo = MockPhoto(
      id: 'photo_$seq',
      seed: seq,
      localPath: picked.path.isEmpty ? null : picked.path,
      bytes: picked.bytes.isEmpty ? null : picked.bytes,
    );
    final photos = [...state.photos, photo];
    state = state.copyWith(
      photos: photos,
      primaryPhotoId: state.primaryPhotoId ?? photo.id,
    );
  }

  /// Test / seed helper when gallery is unavailable.
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

