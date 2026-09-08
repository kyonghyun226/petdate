import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/firebase/firestore_ids.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/state/profile_provider.dart';

/// pets/{petId} ↔ UI models. petId == ownerId == uid.
abstract final class PetCodec {
  static Map<String, dynamic> toFirestore({
    required String uid,
    required ProfileDraft draft,
  }) {
    final photos = draft.photos.isEmpty
        ? <String>[FirestoreIds.photoPath(petId: uid, fileName: 'photo_0')]
        : [
            for (final photo in draft.photos)
              FirestoreIds.photoPath(
                petId: uid,
                fileName: 'photo_${photo.seed}',
              ),
          ];
    final age = (draft.displayAgeYears ?? 0).clamp(0, 40);
    return {
      'ownerId': uid,
      'name': draft.displayName,
      'species': draft.species == PetSpecies.cat ? 'cat' : 'dog',
      'breed': draft.breed.trim().isEmpty ? '믹스' : draft.breed.trim(),
      'age': age,
      'sex': draft.gender == PetGender.female ? 'female' : 'male',
      'size': switch (draft.size) {
        PetSize.medium => 'medium',
        PetSize.large => 'large',
        _ => 'small',
      },
      'photos': photos,
      'tags': draft.tags.toList(),
      'bio': draft.bio,
      'preferredTimeSlots': [
        for (final slot in draft.preferredTimeSlots) slot.name,
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DiscoveryProfile? toDiscovery(
    String id,
    Map<String, dynamic>? data, {
    bool likedMe = false,
    double distanceKm = 0,
  }) {
    if (data == null) return null;
    final name = data['name'] as String? ?? '';
    if (name.isEmpty) return null;
    final photos = _stringList(data['photos']);
    final tags = _stringList(data['tags']);
    final slots = [
      for (final raw in _stringList(data['preferredTimeSlots']))
        if (_slot(raw) != null) _slot(raw)!,
    ];
    return DiscoveryProfile(
      id: id,
      name: name,
      ageYears: _int(data['age']) ?? 0,
      distanceKm: distanceKm,
      breed: data['breed'] as String? ?? '',
      species: data['species'] == 'cat' ? PetSpecies.cat : PetSpecies.dog,
      gender: data['sex'] == 'female' ? PetGender.female : PetGender.male,
      size: switch (data['size']) {
        'medium' => PetSize.medium,
        'large' => PetSize.large,
        _ => PetSize.small,
      },
      tagKeys: tags,
      bio: data['bio'] as String? ?? '',
      photoSeeds: [
        for (final path in photos) FirestoreIds.seedFromPhotoPath(path),
      ],
      preferredTimeSlots: slots,
      likedMe: likedMe,
    );
  }

  static ProfileDraft? toDraft(String id, Map<String, dynamic>? data) {
    final profile = toDiscovery(id, data);
    if (profile == null) return null;
    final photos = [
      for (var i = 0; i < profile.photoSeeds.length; i++)
        MockPhoto(id: 'photo_$i', seed: profile.photoSeeds[i]),
    ];
    return ProfileDraft(
      petName: profile.name,
      species: profile.species,
      breed: profile.breed,
      ageYears: profile.ageYears,
      gender: profile.gender,
      size: profile.size,
      photos: photos,
      primaryPhotoId: photos.isEmpty ? null : photos.first.id,
      tags: profile.tagKeys.toSet(),
      preferredTimeSlots: profile.preferredTimeSlots.toSet(),
      bio: profile.bio.length > AppConstants.bioMax
          ? profile.bio.substring(0, AppConstants.bioMax)
          : profile.bio,
    );
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return [for (final item in raw) if (item is String) item];
  }

  static int? _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }

  static PreferredTimeSlot? _slot(String raw) {
    for (final slot in PreferredTimeSlot.values) {
      if (slot.name == raw) return slot;
    }
    return null;
  }
}
