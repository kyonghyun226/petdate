import 'package:flutter/foundation.dart';
import 'package:petdate/firebase/owner_codec.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/state/profile_provider.dart';

@immutable
class DiscoveryProfile {
  const DiscoveryProfile({
    required this.id,
    required this.name,
    required this.ageYears,
    required this.distanceKm,
    required this.breed,
    required this.species,
    required this.gender,
    required this.size,
    required this.tagKeys,
    required this.bio,
    required this.photoSeeds,
    required this.preferredTimeSlots,
    this.mainPhotoAsset,
    this.ownerAgeBand,
    this.ownerGender,
    this.dogExperience,
    this.likedMe = false,
    this.noseCount = 0,
    this.latitude,
    this.longitude,
  });

  /// Distance unknown (peer has no geo, or origin missing).
  static const unknownDistanceKm = -1.0;

  final String id;
  final String name;
  final int ageYears;
  final double distanceKm;
  final String breed;
  final PetSpecies species;
  final PetGender gender;
  final PetSize size;
  final List<String> tagKeys;
  final String bio;
  final List<int> photoSeeds;
  final List<PreferredTimeSlot> preferredTimeSlots;

  /// Demo catalog: bundled asset path for the primary profile photo.
  final String? mainPhotoAsset;
  final OwnerAgeBand? ownerAgeBand;
  final OwnerGender? ownerGender;
  final DogExperience? dogExperience;

  /// Mock: this profile already sent a spark to the current user.
  /// Live: derived from likes where toOwnerId == me.
  final bool likedMe;

  /// Public 「코인사」 count (others' nose greetings). Local toggles add +1.
  final int noseCount;

  /// Approximate peer coordinates from pets.latlng (null if unset).
  final double? latitude;
  final double? longitude;

  int get photoCount => photoSeeds.isEmpty ? 1 : photoSeeds.length;

  int get mainPhotoSeed => photoSeeds.isEmpty ? 0 : photoSeeds.first;

  String get distanceLabel => formatPetDistance(distanceKm);

  bool get hasGeo => latitude != null && longitude != null;

  bool get hasOwnerInfo =>
      ownerAgeBand != null || ownerGender != null || dogExperience != null;

  String? get ownerSummary => OwnerCodec.summaryLine(
        ageBand: ownerAgeBand,
        gender: ownerGender,
        experience: dogExperience,
      );

  DiscoveryProfile copyWith({
    bool? likedMe,
    int? noseCount,
    double? distanceKm,
    double? latitude,
    double? longitude,
  }) {
    return DiscoveryProfile(
      id: id,
      name: name,
      ageYears: ageYears,
      distanceKm: distanceKm ?? this.distanceKm,
      breed: breed,
      species: species,
      gender: gender,
      size: size,
      tagKeys: tagKeys,
      bio: bio,
      photoSeeds: photoSeeds,
      preferredTimeSlots: preferredTimeSlots,
      mainPhotoAsset: mainPhotoAsset,
      ownerAgeBand: ownerAgeBand,
      ownerGender: ownerGender,
      dogExperience: dogExperience,
      likedMe: likedMe ?? this.likedMe,
      noseCount: noseCount ?? this.noseCount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

String formatPetDistance(double km) {
  if (km < 0) return '—';
  if (km <= 0) return '근처';
  if (km < 1) return '${(km * 1000).round()}m';
  return '${km.toStringAsFixed(1)}km';
}
