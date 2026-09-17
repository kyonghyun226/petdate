import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/models/pet_tag.dart';

abstract final class AppCopy {
  static const appName = '반짝산책';
  static const loginTitle = '반려견의 짝꿍과 함께 산책해요';
  static const loginCaption = '펫 친구 · 산책 메이트';
  static const loginGoogle = 'Google로 계속하기';
  static const loginApple = 'Apple로 계속하기';
  static const loginGuestPreview = '로그인 없이 둘러보기';
  static const loginFailed = '로그인에 실패했어요. 다시 시도해 주세요.';

  /// Play / App Store listing placeholders (not shown in-app).
  static const storeSubtitle = '반려견 친구 · 산책 메이트 찾기';
  static const storeTagline =
      '우리 반려의 짝을 찾아요. 친구 사귀기부터 같이 산책하기까지.';

  static const meetupAccept = '수락';
  static const meetupCounter = '다른 시간 제안';
  static const meetupIgnore = '무시';
  static const meetupAccepted = '수락했어요';
  static const meetupCountered = '다른 시간을 제안했어요';
  static const meetupIgnored = '무시했어요';
  static const petNounFallback = '반려견';
  static const petNounDog = '강아지';

  static const onboardingStart = '시작하기';
  static const alreadyHaveAccount = '이미 계정 있어요';

  static const List<OnboardingPageCopy> onboardingPages = [
    OnboardingPageCopy(
      title: '우리 반려견의 짝꿍을 찾아요',
      body: '우리 아이랑 잘 맞는 친구, 같이 산책할 메이트를 반짝 만나보세요.',
    ),
    OnboardingPageCopy(
      title: '라이프스타일이 맞는 견주',
      body: '태그·시간대를 알려 주시면, 잘 맞는 반려견 친구를 추천해 드려요.',
    ),
    OnboardingPageCopy(
      title: '안전하게, 반짝',
      body: '반려견등록 인증으로 시작하고, 불편하면 차단·신고도 바로. 준비됐으면 Google 또는 Apple로 시작해요.',
    ),
  ];

  static const next = '다음';
  static const startSpark = '반짝 시작하기';
  static const saveProfile = '저장하기';
  static const profileSaveFailed = '프로필을 저장하지 못했어요. 다시 시도해 주세요.';
  static const refresh = '새로고침';
  static const later = '나중에';
  static const startChat = '채팅 시작';
  static const startConversation = '대화 시작하기';
  static const send = '보내기';
  static const goHome = '홈으로';

  static const navHome = '홈';
  static const navSpark = '반짝';
  static const navChat = '채팅';
  static const navMeongstar = '멍스타';
  static const navMy = '마이페이지';

  static const homeTitle = '오늘의 반짝 친구';
  static const homeEmpty =
      '아직 근처에 반짝할 친구가 없어요. 조금 이따 다시 봐볼까요?';
  static const meongstarEmpty = '아직 등록된 강아지가 없어요';
  static const bioPlaceholder = '초코는 새 친구를 기다리면 꼬리가 먼저 반짝해요';

  static const noseGreeting = '코인사';
  static const noseGreetingTooltip = '코인사하기';
  static String noseGreetingCount(int count) => '코인사 $count';

  /// Send-like CTA on D01 (오늘의 반짝 친구 → 프로필). Uses *my* pet name.
  static String detailCta(String myPetName) => '우리 $myPetName와 친구하자!';

  /// Reply CTA on D01 opened from B01 received. Uses *their* pet name.
  static String sparkReplyCta(String theirPetName) =>
      '우리 $theirPetName와 친구될래?';

  static String matchBody(String mine, String theirs) =>
      '$mine와 $theirs가 친구가 됐어요. 인사해 볼까요?';

  static const sparkReceived = '받은';
  static const sparkSent = '보낸';
  static const sparkMatched = '매칭됨';
  static const sparkReply = '반짝 화답';
  static const sparkEmpty = '아직 받은 반짝이 없어요';
  static const sparkSentEmpty = '아직 보낸 반짝이 없어요';
  static const sparkMatchedEmpty = '아직 반짝한 친구가 없어요';

  static const chatEmpty = '아직 반짝한 친구가 없어요';
  static const chatEmptyHint = '서로 반짝하면 여기에서 인사할 수 있어요.';
  static const chatMembersOnly = '이 대화는 참여자만 볼 수 있어요';
  static const viewProfile = '프로필';
  static const reportMenuItem = '신고';
  static const blockMenuItem = '차단';
  static const chatInputHint = '메시지 보내기';

  static const p00Title = '견주 정보';
  static const p00Subtitle = '우리 반려견을 돌보는 분에 대해 알려 주세요.';
  static const p01Title = '기본 정보';
  static const p02Title = '사진';
  static const p03Title = '태그';
  static const p03TimeTitle = '주로 만나는 시간';
  static const p03TimeHint = '편한 시간대를 1~3개 골라 주세요.';
  static const p04Title = '한 줄 소개';

  static const ownerAgeLabel = '나이대';
  static const ownerAgeTwenties = '20대';
  static const ownerAgeThirties = '30대';
  static const ownerAgeForties = '40대';
  static const ownerAgeFiftiesPlus = '50대 이상';

  static const ownerGenderLabel = '성별';
  static const ownerGenderMale = '남성';
  static const ownerGenderFemale = '여성';

  static const dogExperienceLabel = '반려견을 키운 경험';
  static const dogExperienceHint = '지금까지 반려견과 함께한 기간을 골라 주세요.';
  static const dogExperienceFirst = '처음이에요';
  static const dogExperienceUnderOne = '1년 미만';
  static const dogExperienceOneToThree = '1–3년';
  static const dogExperienceThreeToFive = '3–5년';
  static const dogExperienceOverFive = '5년 이상';
  static const ownerSectionLabel = '견주';
  static const ownerExperienceShortPrefix = '경험';

  static const petNameLabel = '이름';
  static const petNameHint = '반려견 이름';
  static const breedLabel = '품종';
  static const breedHint = '예: 말티즈, 포메라니안';
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

  static const myTermsOfService = '이용약관';
  static const myPrivacyPolicy = '개인정보 처리방침';
  static const mySettings = '설정';
  static const myLogout = '로그아웃';
  static const myDeleteAccount = '계정 탈퇴';
  static const deleteAccountTitle = '계정을 탈퇴할까요?';
  static const deleteAccountBody =
      '프로필·매칭·채팅 등 계정 정보가 삭제되며 되돌릴 수 없어요.';
  static const deleteAccountConfirm = '탈퇴하기';
  static const deleteAccountCancel = '취소';
  static const deleteAccountFailed = '탈퇴에 실패했어요. 다시 시도해 주세요.';
  static const settingsTitle = '설정';
  static const settingsLocation = '위치';
  static const settingsLocationHint = '근처 산책 친구를 거리 순으로 보여드려요';
  static const settingsNotifications = '알림';
  static const settingsNotificationsHint = '매칭·새 인사·만남 제안을 알려드려요';
  static const settingsRadius = '검색 반경';

  /// Shown once on first main entry — never at splash/login/signup.
  static const locationPrepromptTitle = '근처 친구를 찾아볼까요?';
  static const locationPrepromptBody =
      '위치를 허용하면 검색 반경 안의 산책 친구를 보여드려요. '
      '정확한 주소는 저장하지 않고, 대략적인 위치만 사용해요.';
  static const locationPrepromptAllow = '허용하기';
  static const locationPrepromptDeny = '나중에';

  /// Shown once, immediately after the first M01 match — never at signup.
  static const pushPrepromptTitle = '반짝 소식 받으실래요?';
  static const pushPrepromptBody =
      '매칭이 되면, 새 인사와 만남 제안을 알려드릴게요. 반려 친구·산책 소식만 보내요.';
  static const pushPrepromptAllow = '받을게요';
  static const pushPrepromptDeny = '나중에';
  static const pushMatchTitle = '반짝 매칭!';
  static const pushMatchBody = '산책 짝이 생겼어요. 인사해 볼까요?';
  static const pushMessageTitle = '새 메시지';
  static const pushMessageBody = '반짝한 친구에게 인사가 도착했어요';
  static const pushMeetupTitle = '만남 제안';
  static const pushMeetupBody = '같이 걸을 장소·시간이 도착했어요';
  static const fallbackPetName = '우리 아이';

  static const passTooltip = '패스';
  static const likeTooltip = '좋아요';
  static const likeNeedsVerify = '인증 후 반짝할 수 있어요';

  static const filterTooltip = '검색 필터';
  static const filterTitle = '검색 필터';
  static const filterSubtitle = '원하는 반려견·견주 조건으로 반짝 친구를 찾아보세요.';
  static const filterRadiusLabel = '검색 반경';
  static const filterPetSection = '반려견';
  static const filterOwnerSection = '견주';
  static const filterAgeLabel = '나이';
  static const filterAgeUnderOne = '1살 미만';
  static const filterAgeOneToThree = '1–3살';
  static const filterAgeThreeToSeven = '3–7살';
  static const filterAgeOverSeven = '7살 이상';
  static const filterTagsLabel = '라이프스타일';
  static const filterTimeLabel = '만나는 시간';
  static const filterApply = '적용하기';
  static const filterReset = '초기화';
  static const filterEmpty =
      '조건에 맞는 친구가 없어요. 필터를 조금 넓혀 볼까요?';
  static const filterClearAction = '필터 초기화';

  static const verifyTitle = '반려견등록 인증';
  static const verifyBody =
      '국가동물보호정보시스템에 등록된 소유주 이름과 동물등록번호를 입력해 주세요. 확인 후 인증 뱃지를 드려요.';
  static const verifyCta = '심사 요청하기';
  static const verifyGateCta = '인증하러 가기';
  static const verifyOwnerHint = '소유주 이름';
  static const verifyOwnerPlaceholder = '홍길동';
  static const verifyRegHint = '동물등록번호';
  static const verifyRegPlaceholder = '410000000000000';
  static const verifyInvalidOwner = '소유주 이름을 입력해 주세요.';
  static const verifyInvalidReg = '동물등록번호(숫자)를 확인해 주세요.';
  static const verifySubmitFailed = '요청을 보내지 못했어요. 잠시 후 다시 시도해 주세요.';
  static const verifyPendingTitle = '심사를 진행 중이에요';
  static const verifyPendingBody =
      '등록 정보를 확인한 뒤 인증 뱃지를 드려요. 보통 영업일 기준 1–2일 걸려요.';
  static const verifyDone = '인증됐어요';
  static const verifySuccessBody = '이제 반짝으로 친구·산책 메이트를 만날 수 있어요';
  static const verifyAlreadyDoneBody = '반려견등록 인증이 완료되었어요.';
  static const verifyGoSpark = '반짝하러 가기';
  static const verifyGateTitle = '안전하게 반짝해요';
  static const verifyGateBody =
      '반려견등록 인증을 마치면 좋아요를 보낼 수 있어요. 반려 친구·산책 메이트를 위한 한 걸음이에요.';
  static const verifyStatusVerified = '인증됨';
  static const verifyStatusPending = '심사중';
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
  static const meetupTitle = '어디서 만날까요?';
  static const meetupPlace = '장소';
  static const meetupTime = '시간';
  static const meetupMemo = '메모';
  static const meetupMemoHint = '만날 때 참고할 한 줄을 남겨 주세요';
  static const meetupOtherHint = '장소 이름 또는 동네';
  static const meetupSent = '만남 제안을 보냈어요';
  static const meetupTonight = '오늘 저녁';
  static const meetupThisWeekend = '이번 주말';
  static const meetupPickDateTime = '날짜·시간 선택';

  static const List<String> meetupTimeChips = [
    meetupTonight,
    meetupThisWeekend,
    meetupPickDateTime,
  ];

  static const List<PetTag> petTags = PetTags.all;
}

class OnboardingPageCopy {
  const OnboardingPageCopy({required this.title, required this.body});

  final String title;
  final String body;
}
