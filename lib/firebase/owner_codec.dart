import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/profile_provider.dart';

/// Codec + display labels for owner fields on `users/{uid}` and `pets/{uid}`.
abstract final class OwnerCodec {
  static const ageBandField = 'ownerAgeBand';
  static const genderField = 'ownerGender';
  static const experienceField = 'dogExperience';

  static String ageBandKey(OwnerAgeBand value) => switch (value) {
        OwnerAgeBand.twenties => 'twenties',
        OwnerAgeBand.thirties => 'thirties',
        OwnerAgeBand.forties => 'forties',
        OwnerAgeBand.fiftiesPlus => 'fiftiesPlus',
      };

  static String genderKey(OwnerGender value) => switch (value) {
        OwnerGender.male => 'male',
        OwnerGender.female => 'female',
      };

  static String experienceKey(DogExperience value) => switch (value) {
        DogExperience.firstTime => 'firstTime',
        DogExperience.underOneYear => 'underOneYear',
        DogExperience.oneToThree => 'oneToThree',
        DogExperience.threeToFive => 'threeToFive',
        DogExperience.overFive => 'overFive',
      };

  static OwnerAgeBand? parseAgeBand(Object? raw) => switch (raw) {
        'twenties' => OwnerAgeBand.twenties,
        'thirties' => OwnerAgeBand.thirties,
        'forties' => OwnerAgeBand.forties,
        'fiftiesPlus' => OwnerAgeBand.fiftiesPlus,
        _ => null,
      };

  static OwnerGender? parseGender(Object? raw) => switch (raw) {
        'male' => OwnerGender.male,
        'female' => OwnerGender.female,
        _ => null,
      };

  static DogExperience? parseExperience(Object? raw) => switch (raw) {
        'firstTime' => DogExperience.firstTime,
        'underOneYear' => DogExperience.underOneYear,
        'oneToThree' => DogExperience.oneToThree,
        'threeToFive' => DogExperience.threeToFive,
        'overFive' => DogExperience.overFive,
        _ => null,
      };

  static Map<String, String> toFirestore({
    required OwnerAgeBand ageBand,
    required OwnerGender gender,
    required DogExperience experience,
  }) =>
      {
        ageBandField: ageBandKey(ageBand),
        genderField: genderKey(gender),
        experienceField: experienceKey(experience),
      };

  static String ageBandLabel(OwnerAgeBand value) => switch (value) {
        OwnerAgeBand.twenties => AppCopy.ownerAgeTwenties,
        OwnerAgeBand.thirties => AppCopy.ownerAgeThirties,
        OwnerAgeBand.forties => AppCopy.ownerAgeForties,
        OwnerAgeBand.fiftiesPlus => AppCopy.ownerAgeFiftiesPlus,
      };

  static String genderLabel(OwnerGender value) => switch (value) {
        OwnerGender.male => AppCopy.ownerGenderMale,
        OwnerGender.female => AppCopy.ownerGenderFemale,
      };

  static String experienceLabel(DogExperience value) => switch (value) {
        DogExperience.firstTime => AppCopy.dogExperienceFirst,
        DogExperience.underOneYear => AppCopy.dogExperienceUnderOne,
        DogExperience.oneToThree => AppCopy.dogExperienceOneToThree,
        DogExperience.threeToFive => AppCopy.dogExperienceThreeToFive,
        DogExperience.overFive => AppCopy.dogExperienceOverFive,
      };

  /// Compact line for discovery cards, e.g. `30대 · 여성 · 경험 1–3년`.
  static String? summaryLine({
    OwnerAgeBand? ageBand,
    OwnerGender? gender,
    DogExperience? experience,
  }) {
    final parts = <String>[
      if (ageBand != null) ageBandLabel(ageBand),
      if (gender != null) genderLabel(gender),
      if (experience != null)
        '${AppCopy.ownerExperienceShortPrefix} ${experienceLabel(experience)}',
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}
