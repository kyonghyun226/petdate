import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/models/pet_tag.dart';

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
  static const loginFailed = '로그인에 실패했어요. 다시 시도해 주세요.';

  /// Play / App Store listing placeholders (not shown in-app).
  static const storeSubtitle = '반려 친구 · 산책 메이트 찾기';
  static const storeTagline =
      '우리 반려의 짝을 찾아요. 친구 사귀기부터 같이 산책하기까지.';

  static const filterAll = '전체';
  static const meetupAccept = '수락';
  static const meetupCounter = '다른 시간 제안';
  static const meetupIgnore = '무시';
  static const meetupAccepted = '수락했어요';
  static const meetupCountered = '다른 시간을 제안했어요';
  static const meetupIgnored = '무시했어요';
  static const petNounFallback = '반려';
  static const petNounDog = '강아지';
  static const petNounCat = '고양이';

  static const onboardingStart = '시작하기';
  static const alreadyHaveAccount = '이미 계정 있어요';

  static const List<OnboardingPageCopy> onboardingPages = [
    OnboardingPageCopy(
      title: '우리 반려의 짝을 찾아요',
      body: '우리 아이랑 잘 맞는 친구, 같이 산책할 메이트를 반짝 만나보세요.',
    ),
    OnboardingPageCopy(
      title: '친구 사귀기 · 같이 산책하기',
      body: '원하는 목적만 고르면, 라이프스타일이 맞는 견주·묘주를 추천해 드려요.',
    ),
    OnboardingPageCopy(
      title: '안전하게, 반짝',
      body: '본인인증으로 시작하고, 불편하면 차단·신고도 바로. 준비됐으면 Google 또는 Apple로 시작해요.',
    ),
  ];

  static const goalQuestion = '반짝산책에서 무엇을 하고 싶어요?';
  static const goalFriendTitle = '친구 사귀기';
  static const goalFriendDesc = '우리 반려의 친구를 만나요';
  static const goalWalkTitle = '같이 산책하기';
  static const goalWalkDesc = '주말에 같이 걸을 짝을 찾아요';
  static const goalApply = '적용하기';

  static const next = '다음';
  static const startSpark = '반짝 시작하기';
  static const refresh = '새로고침';
  static const later = '나중에';
  static const startChat = '채팅 시작';
  static const send = '보내기';
  static const goHome = '홈으로';

  static const navHome = '홈';
  static const navSpark = '반짝';
  static const navChat = '채팅';
  static const navMy = '마이';

  static const sparkReceived = '받은';
  static const sparkSent = '보낸';
  static const sparkMatched = '매칭됨';
  static const sparkReply = '반짝 화답';
  static const sparkEmpty = '아직 받은 반짝이 없어요';
  static const sparkSentEmpty = '아직 보낸 반짝이 없어요';
  static const sparkMatchedEmpty = '아직 반짝한 친구가 없어요';

  static const chatEmpty = '아직 반짝한 친구가 없어요';
  static const chatEmptyHint = '서로 반짝하면 여기에서 인사할 수 있어요.';

  static const p01Title = '기본 정보';
  static const p02Title = '사진';
  static const p03Title = '태그';
  static const p03TimeTitle = '주로 만나는 시간';
  static const p03TimeHint = '편한 시간대를 1~3개 골라 주세요.';
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

  static const bioMax = AppConstants.bioMax;
  static const requiredMark = '필수';

  static const fieldRequired = '이 항목은 필수예요.';
  static const ageOrBirthRequired = '나이 또는 생년월을 입력해 주세요.';
  static const photoRequired = '사진을 1장 이상 넣어 주세요.';
  static const tagMinRequired = '태그를 3개 이상 골라 주세요.';
  static const timeSlotRequired = '시간대를 1개 이상 골라 주세요.';

  static const myChangeGoal = '목적 변경';
  static const mySettings = '설정';
  static const myLogout = '로그아웃';
  static const settingsTitle = '설정';
  static const settingsRadius = '검색 반경';
  static const settingsSoon = '알림·계정 설정은 곧 열려요.';
  static const fallbackPetName = '우리 아이';

  static const passTooltip = '패스';
  static const likeTooltip = '좋아요';
  static const likeNeedsVerify = '인증 후 반짝할 수 있어요';

  static const verifyTitle = '본인인증';
  static const verifyBody = '반짝하려면 본인인증이 필요해요. 인증이 끝나면 친구 사귀기·같이 산책하기를 바로 이어갈 수 있어요.';
  static const verifyCta = '인증하기';
  static const verifyDone = '인증됐어요';
  static const verifySuccessBody = '이제 반짝으로 친구·산책 메이트를 만날 수 있어요';
  static const verifyGoSpark = '반짝하러 가기';
  static const verifyGateTitle = '안전하게 반짝해요';
  static const verifyGateBody =
      '본인인증을 마치면 좋아요를 보낼 수 있어요. 반려 친구·산책 메이트를 위한 한 걸음이에요.';
  static const verifyStatusVerified = '인증됨';
  static const verifyStatusUnverified = '미인증';

  static const reportMenu = '신고 · 차단';
  static const reportTitle = '이 프로필을 신고할까요?';
  static const reportHint = '허위·스팸·불편한 행동은 신고해 주세요. 차단하면 더 이상 보이지 않아요.';
  static const blockLabel = '차단하기';
  static const reportLabel = '신고하기';
  static const reportSent = '신고가 접수됐어요';
  static const close = '닫기';

  static const safetyBanner = '만남은 공공장소에서, 반려와 함께 안전하게';
  static const matchTitle = '반짝 매칭!';
  static const chatSystemMatch =
      '반짝 매칭을 축하해요! 산책이나 카페 약속을 제안해 보세요';
  static const proposeMeetup = '만남 제안';
  static const meetupPlace = '장소';
  static const meetupTime = '시간';
  static const meetupMemo = '메모';
  static const meetupMemoHint = '만날 때 참고할 한 줄을 남겨 주세요';
  static const meetupOtherHint = '장소 이름 또는 동네';
  static const meetupSent = '만남 제안을 보냈어요';

  static const List<String> meetupTimeChips = [
    '오늘 저녁',
    '내일 오전',
    '주말 아침',
    '주말 오후',
  ];

  static const List<PetTag> petTags = PetTags.all;
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

  static String detailCta(UserGoal goal, String name) => switch (goal) {
        UserGoal.friend => '우리 $name와 친구될래?',
        UserGoal.walk => '우리 $name와 산책할래?',
      };

  static String matchBody(UserGoal goal, String mine, String theirs) =>
      switch (goal) {
        UserGoal.friend => '$mine와 $theirs가 친구가 됐어요. 인사해 볼까요?',
        UserGoal.walk => '$mine와 $theirs가 산책 짝이 됐어요. 언제 걸어볼까요?',
      };

  static List<String> firstMessageChips(UserGoal goal, String myPet) =>
      switch (goal) {
        UserGoal.friend => [
            '우리 $myPet는 새 친구 기다리면 꼬리부터 반짝해요',
            '한강·공원 산책 좋아해요. 같이 가볼래요?',
            '펫카페도 좋아해요',
          ],
        UserGoal.walk => [
            '주말 아침 산책 가능해요',
            '퇴근 후 짧게 걸을래요',
            '이번 주말 시간 맞춰볼까요?',
          ],
      };
}
