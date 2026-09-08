class PetTag {
  const PetTag({required this.key, required this.label});

  final String key;
  final String label;
}

/// P03 lifestyle tags (12). Preferred time slots are separate.
abstract final class PetTags {
  static const walkLover = PetTag(key: 'walk_lover', label: '산책 좋아해요');
  static const cafeLover = PetTag(key: 'cafe_lover', label: '카페 가는 걸 즐겨요');
  static const nightActive = PetTag(key: 'night_active', label: '밤에 활발해요');
  static const napLover = PetTag(key: 'nap_lover', label: '낮잠 매니아');
  static const carefulWithStrangers = PetTag(
    key: 'careful_with_strangers',
    label: '낯선 개 조심해요',
  );
  static const socialButterfly = PetTag(
    key: 'social_butterfly',
    label: '친구 많아요',
  );
  static const quietMeetups = PetTag(
    key: 'quiet_meetups',
    label: '조용한 만남 좋아요',
  );
  static const parkLover = PetTag(key: 'park_lover', label: '공원 러버');
  static const indoor = PetTag(key: 'indoor', label: '실내파');
  static const weekendMorning = PetTag(
    key: 'weekend_morning',
    label: '주말 아침형',
  );
  static const afterWorkWalk = PetTag(
    key: 'after_work_walk',
    label: '퇴근 후 산책',
  );
  static const travelMate = PetTag(key: 'travel_mate', label: '여행 메이트');

  static const List<PetTag> all = [
    walkLover,
    cafeLover,
    nightActive,
    napLover,
    carefulWithStrangers,
    socialButterfly,
    quietMeetups,
    parkLover,
    indoor,
    weekendMorning,
    afterWorkWalk,
    travelMate,
  ];

  static PetTag? byKey(String key) {
    for (final tag in all) {
      if (tag.key == key) return tag;
    }
    return null;
  }

  static String labelOf(String key) => byKey(key)?.label ?? key;
}
