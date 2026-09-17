import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/data/demo_assets.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/pet_tag.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/state/profile_provider.dart';

abstract final class MockCatalog {
  /// Own pet card for guest preview (no Auth / private test track).
  static final guestOwnerDraft = ProfileDraft(
    step: ProfileDraft.lastStep,
    ownerAgeBand: OwnerAgeBand.twenties,
    ownerGender: OwnerGender.female,
    dogExperience: DogExperience.oneToThree,
    petName: '초코',
    breed: '믹스',
    ageYears: 3,
    gender: PetGender.female,
    size: PetSize.small,
    photos: const [
      MockPhoto(id: 'guest_0', seed: 7),
    ],
    primaryPhotoId: 'guest_0',
    tags: {
      PetTags.walkLover.key,
      PetTags.parkLover.key,
      PetTags.socialButterfly.key,
    },
    preferredTimeSlots: const {
      PreferredTimeSlot.weekendMorning,
      PreferredTimeSlot.weekdayEvening,
    },
    bio: '비공개 테스트용 데모 프로필이에요. 로그인 없이 둘러볼 수 있어요.',
  );

  static final profiles = <DiscoveryProfile>[
    DiscoveryProfile(
      id: 'kong',
      name: '콩이',
      ageYears: 2,
      distanceKm: 0.8,
      breed: '말티즈',
      species: PetSpecies.dog,
      gender: PetGender.male,
      size: PetSize.small,
      tagKeys: [
        PetTags.walkLover.key,
        PetTags.socialButterfly.key,
        PetTags.parkLover.key,
      ],
      bio: '꼬리부터 반짝하는 말티즈예요. 공원에서 친구 만드는 중!',
      photoSeeds: [1, 11, 21],
      mainPhotoAsset: DemoAssets.dog1,
      preferredTimeSlots: [
        PreferredTimeSlot.weekendMorning,
        PreferredTimeSlot.weekdayEvening,
      ],
      ownerAgeBand: OwnerAgeBand.twenties,
      ownerGender: OwnerGender.female,
      dogExperience: DogExperience.oneToThree,
      likedMe: true,
      noseCount: 128,
    ),
    DiscoveryProfile(
      id: 'bori',
      name: '보리',
      ageYears: 4,
      distanceKm: 1.4,
      breed: '코커스패니얼',
      species: PetSpecies.dog,
      gender: PetGender.female,
      size: PetSize.medium,
      tagKeys: [
        PetTags.cafeLover.key,
        PetTags.quietMeetups.key,
        PetTags.afterWorkWalk.key,
      ],
      bio: '카페 테라스와 짧은 저녁 산책이 제일 좋아요.',
      photoSeeds: [2, 12],
      mainPhotoAsset: DemoAssets.dog2,
      preferredTimeSlots: [PreferredTimeSlot.weekdayEvening],
      ownerAgeBand: OwnerAgeBand.thirties,
      ownerGender: OwnerGender.female,
      dogExperience: DogExperience.threeToFive,
      noseCount: 42,
    ),
    DiscoveryProfile(
      id: 'bam',
      name: '밤이',
      ageYears: 3,
      distanceKm: 2.1,
      breed: '시츄',
      species: PetSpecies.dog,
      gender: PetGender.female,
      size: PetSize.small,
      tagKeys: [
        PetTags.napLover.key,
        PetTags.cafeLover.key,
        PetTags.quietMeetups.key,
      ],
      bio: '낮엔 낮잠, 저녁엔 짧은 산책. 조용한 친구 환영해요.',
      photoSeeds: [3, 13, 23],
      mainPhotoAsset: DemoAssets.dog3,
      preferredTimeSlots: [PreferredTimeSlot.weekendAfternoon],
      ownerAgeBand: OwnerAgeBand.forties,
      ownerGender: OwnerGender.male,
      dogExperience: DogExperience.overFive,
      likedMe: true,
      noseCount: 67,
    ),
    DiscoveryProfile(
      id: 'dal',
      name: '달이',
      ageYears: 5,
      distanceKm: 3.2,
      breed: '골든리트리버',
      species: PetSpecies.dog,
      gender: PetGender.male,
      size: PetSize.large,
      tagKeys: [
        PetTags.walkLover.key,
        PetTags.travelMate.key,
        PetTags.weekendMorning.key,
      ],
      bio: '주말 아침 한강, 가끔은 근교 여행도 같이 가요.',
      photoSeeds: [4, 14],
      mainPhotoAsset: DemoAssets.dog4,
      preferredTimeSlots: [
        PreferredTimeSlot.weekendMorning,
        PreferredTimeSlot.weekendAfternoon,
      ],
      ownerAgeBand: OwnerAgeBand.thirties,
      ownerGender: OwnerGender.male,
      dogExperience: DogExperience.oneToThree,
      noseCount: 215,
    ),
    DiscoveryProfile(
      id: 'gureum',
      name: '구름',
      ageYears: 1,
      distanceKm: 4.6,
      breed: '포메라니안',
      species: PetSpecies.dog,
      gender: PetGender.female,
      size: PetSize.small,
      tagKeys: [
        PetTags.carefulWithStrangers.key,
        PetTags.parkLover.key,
        PetTags.cafeLover.key,
      ],
      bio: '처음엔 조심스럽지만, 친해지면 구름처럼 들떠요.',
      photoSeeds: [5, 15],
      mainPhotoAsset: DemoAssets.dog5,
      preferredTimeSlots: [PreferredTimeSlot.weekendAfternoon],
      ownerAgeBand: OwnerAgeBand.twenties,
      ownerGender: OwnerGender.female,
      dogExperience: DogExperience.firstTime,
      noseCount: 19,
    ),
  ];

  static List<DiscoveryProfile> withinRadius({
    double radiusKm = AppConstants.searchRadiusKm,
  }) {
    return [
      for (final p in profiles)
        if (p.distanceKm <= radiusKm) p,
    ];
  }

  static DiscoveryProfile? byId(String id) {
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    if (id == blocked.id) return blocked;
    return null;
  }

  /// Inbound spark that is blocked — B01 must hide this row.
  static final blocked = DiscoveryProfile(
    id: 'nuri',
    name: '누리',
    ageYears: 6,
    distanceKm: 0.3,
    breed: '시바',
    species: PetSpecies.dog,
    gender: PetGender.male,
    size: PetSize.medium,
    tagKeys: [
      PetTags.walkLover.key,
      PetTags.parkLover.key,
      PetTags.quietMeetups.key,
    ],
    bio: '차단된 목 프로필이에요.',
    photoSeeds: [6],
    preferredTimeSlots: [PreferredTimeSlot.weekendMorning],
    ownerAgeBand: OwnerAgeBand.fiftiesPlus,
    ownerGender: OwnerGender.male,
    dogExperience: DogExperience.overFive,
    likedMe: true,
    noseCount: 3,
  );
}
