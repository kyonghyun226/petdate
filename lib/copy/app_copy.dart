/// Goal-aware copy. [friend] = 펫 친구, [walk] = 산책 메이트.
enum UserGoal { friend, walk }

abstract final class AppCopy {
  static const appName = '반짝산책';
  static const loginTitle = '반려의 짝, 가볍게 반짝';
  static const loginCaption = '펫 친구 · 산책 메이트';
  static const loginGoogle = 'Google로 계속하기';
  static const loginApple = 'Apple로 계속하기';
  static const loginTerms =
      '계속하면 이용약관 및 개인정보 처리방침에 동의하는 것으로 볼게요.';

  static const onboardingStart = '시작하기';
  static const alreadyHaveAccount = '이미 계정 있어요';

  static const List<OnboardingPageCopy> onboardingPages = [
    OnboardingPageCopy(
      title: '우리 반려도 친구가 필요해요',
      body: '같은 동네에서 비슷한 반려를 만나\n가벼운 인사부터 시작해 보세요.',
    ),
    OnboardingPageCopy(
      title: '좋아요로 반짝 인연을 만들어요',
      body: '마음이 가면 반짝, 서로 반짝하면\n대화가 열려요.',
    ),
    OnboardingPageCopy(
      title: '산책·카페에서 자연스럽게 만나요',
      body: '보호자가 함께하는 만남으로\n우리 반려의 페이스에 맞춰요.',
    ),
  ];

  static const goalQuestion = '반짝산책에서 무엇을 하고 싶어요?';
  static const goalFriendTitle = '친구 사귀기';
  static const goalFriendDesc = '우리 반려의 친구를 만나요';
  static const goalWalkTitle = '같이 산책하기';
  static const goalWalkDesc = '주말에 같이 걸을 짝을 찾아요';

  static const next = '다음';
  static const startSpark = '반짝 시작하기';

  static const navHome = '홈';
  static const navSpark = '반짝';
  static const navChat = '채팅';
  static const navMy = '마이';

  static const sparkEmpty = '아직 받은 반짝이 없어요';
  static const chatEmpty = '아직 열린 반짝 대화가 없어요';
  static const chatEmptyHint = '서로 반짝하면 여기에서 인사할 수 있어요.';

  static const p01Title = '기본 정보';
  static const p02Title = '사진';
  static const p03Title = '태그';
  static const p04Title = '한 줄 소개';

  static const petNameLabel = '이름';
  static const petNameHint = '반려 이름';
  static const speciesLabel = '견 / 묘';
  static const speciesDog = '견';
  static const speciesCat = '묘';
  static const breedLabel = '품종';
  static const breedHint = '예: 말티즈, 코리안숏헤어';
  static const ageOrBirthLabel = '나이 / 생년월';
  static const ageTab = '나이';
  static const birthTab = '생년월';
  static const ageHint = '나이 (살)';
  static const genderLabel = '성별';
  static const genderMale = '남아';
  static const genderFemale = '여아';
  static const sizeLabel = '크기';
  static const sizeSmall = '소';
  static const sizeMedium = '중';
  static const sizeLarge = '대';

  static const photoGuide = '얼굴이 잘 보이는 사진이 반짝 확률↑';
  static const photoRequiredHint = '필수 1장 · 권장 3장';
  static const photoPrimary = '대표';
  static const photoSetPrimary = '대표로';
  static const photoAdd = '사진 추가';

  static const tagHint = '우리 반려를 나타내는 태그를 3~8개 골라 주세요.';
  static const tagCount = '3개 이상, 최대 8개';

  static const bioMax = 140;
  static const requiredMark = '필수';

  static const fieldRequired = '이 항목은 필수예요.';
  static const ageOrBirthRequired = '나이 또는 생년월을 입력해 주세요.';
  static const photoRequired = '사진을 1장 이상 넣어 주세요.';
  static const tagMinRequired = '태그를 3개 이상 골라 주세요.';

  static const myPlaceholder = '내 프로필은 곧 여기에서 볼 수 있어요.';

  static const List<String> petTags = [
    '산책 좋아해요',
    '카페 가는 걸 즐겨요',
    '밤에 활발해요',
    '낮잠 매니아',
    '낯선 개 조심해요',
    '친구 많아요',
    '조용한 만남 좋아요',
    '공원 러버',
    '실내파',
    '주말 아침형',
    '퇴근 후 산책',
  ];
}

class OnboardingPageCopy {
  const OnboardingPageCopy({required this.title, required this.body});

  final String title;
  final String body;
}

abstract final class GoalCopy {
  static String homeTitle(UserGoal goal) => switch (goal) {
        UserGoal.friend => '오늘의 반짝 친구',
        UserGoal.walk => '같이 산책할 짝',
      };

  static String homeEmpty(UserGoal goal) => switch (goal) {
        UserGoal.friend => '아직 근처에 반짝할 친구가 없어요. 조금 이따 다시 봐볼까요?',
        UserGoal.walk => '같이 걸을 짝을 찾는 중이에요. 조금만 기다려 주세요',
      };

  static String bioPlaceholder(UserGoal goal) => switch (goal) {
        UserGoal.friend => '초코는 새 친구를 기다리면 꼬리가 먼저 반짝해요',
        UserGoal.walk => '주말 한강 산책 메이트 구해요 (보호자 함께!)',
      };

  static String goalChipLabel(UserGoal goal) => switch (goal) {
        UserGoal.friend => AppCopy.goalFriendTitle,
        UserGoal.walk => AppCopy.goalWalkTitle,
      };
}
