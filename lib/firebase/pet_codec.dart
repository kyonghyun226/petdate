import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/firebase/firestore_ids.dart';
import 'package:petdate/firebase/owner_codec.dart';
import 'package:petdate/location/geo.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/state/profile_provider.dart';

/// pets/{petId} ↔ UI models. petId == ownerId == uid.
abstract final class PetCodec {
  /// Location-only patch (approximate latlng + geohash). Merge/update only.
  static Map<String, dynamic> locationFields(ApproxLatLng point) {
    return {
      'latlng': GeoPoint(point.latitude, point.longitude),
      'geohash': Geo.encodeGeohash(point),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static ApproxLatLng? readLatLng(Map<String, dynamic>? data) {
    if (data == null) return null;
    final raw = data['latlng'];
    if (raw is GeoPoint) {
      return ApproxLatLng(raw.latitude, raw.longitude);
    }
    return null;
  }

  static Map<String, dynamic> toFirestore({
    required String uid,
    required ProfileDraft draft,
  }) {
    final ordered = [
      if (draft.primaryPhoto != null) draft.primaryPhoto!,
      ...draft.photos.where((p) => p.id != draft.primaryPhotoId),
    ];
    final photos = ordered.isEmpty
        ? <String>[FirestoreIds.photoPath(petId: uid, fileName: 'photo_0.jpg')]
        : [
            for (var i = 0; i < ordered.length; i++)
              ordered[i].storagePath ??
                  FirestoreIds.photoPath(
                    petId: uid,
                    fileName: 'photo_$i.jpg',
                  ),
          ];
    final age = (draft.displayAgeYears ?? 0).clamp(0, 40).toInt();
    final map = <String, dynamic>{
      'ownerId': uid,
      'name': draft.displayName,
      'species': 'dog',
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
    final ageBand = draft.ownerAgeBand;
    final ownerGender = draft.ownerGender;
    final experience = draft.dogExperience;
    if (ageBand != null && ownerGender != null && experience != null) {
      map.addAll(
        OwnerCodec.toFirestore(
          ageBand: ageBand,
          gender: ownerGender,
          experience: experience,
        ),
      );
    }
    return map;
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
    final geo = readLatLng(data);
    return DiscoveryProfile(
      id: id,
      name: name,
      ageYears: _int(data['age']) ?? 0,
      distanceKm: distanceKm,
      breed: data['breed'] as String? ?? '',
      species: PetSpecies.dog,
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
      ownerAgeBand: OwnerCodec.parseAgeBand(data[OwnerCodec.ageBandField]),
      ownerGender: OwnerCodec.parseGender(data[OwnerCodec.genderField]),
      dogExperience:
          OwnerCodec.parseExperience(data[OwnerCodec.experienceField]),
      likedMe: likedMe,
      noseCount: _int(data['noseCount']) ?? 0,
      latitude: geo?.latitude,
      longitude: geo?.longitude,
    );
  }

  static ProfileDraft? toDraft(String id, Map<String, dynamic>? data) {
    final profile = toDiscovery(id, data);
    if (profile == null) return null;
    final paths = _stringList(data?['photos']);
    final photos = <MockPhoto>[
      for (var i = 0; i < paths.length; i++)
        MockPhoto(
          id: 'photo_$i',
          seed: FirestoreIds.seedFromPhotoPath(paths[i]),
          storagePath: paths[i],
        ),
    ];
    if (photos.isEmpty) {
      for (var i = 0; i < profile.photoSeeds.length; i++) {
        photos.add(
          MockPhoto(id: 'photo_$i', seed: profile.photoSeeds[i]),
        );
      }
    }
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
      ownerAgeBand: profile.ownerAgeBand,
      ownerGender: profile.ownerGender,
      dogExperience: profile.dogExperience,
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
