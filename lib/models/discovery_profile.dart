import 'package:flutter/foundation.dart';
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
    this.likedMe = false,
  });

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

  /// Mock: this profile already sent a spark to the current user.
  /// Live: derived from likes where toOwnerId == me.
  final bool likedMe;

  int get photoCount => photoSeeds.isEmpty ? 1 : photoSeeds.length;

  DiscoveryProfile copyWith({bool? likedMe}) {
    return DiscoveryProfile(
      id: id,
      name: name,
      ageYears: ageYears,
      distanceKm: distanceKm,
      breed: breed,
      species: species,
      gender: gender,
      size: size,
      tagKeys: tagKeys,
      bio: bio,
      photoSeeds: photoSeeds,
      preferredTimeSlots: preferredTimeSlots,
      likedMe: likedMe ?? this.likedMe,
    );
  }
}
