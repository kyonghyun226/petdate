# 반짝산책 (petdate)

반려견 친구 · 산책 메이트 찾기. Flutter 앱, Firebase 프로젝트 `petdatinglove`.

Pet registration verification: the client writes `petReg*` fields for manual
review; `users/{uid}.verifiedAt` is written only by Admin / `markUserVerified`.
See [`functions/README.md`](functions/README.md).

## Firebase Auth (Google + Apple)

앱 코드는 Firebase Auth에 연결되어 있습니다. **콘솔 토글과 OAuth 클라이언트는 이 저장소에서 끝낼 수 없습니다.** 아래를 마쳐야 실기기에서 로그인이 됩니다.

### 공통

1. [Firebase console](https://console.firebase.google.com/project/petdatinglove/authentication/providers) → Authentication → Sign-in method
2. **Google** 사용 설정 (지원 이메일 확인)
3. **Apple** 사용 설정

### Android — Google

1. 디버그/릴리스 키스토어 SHA-1 (및 Play App Signing SHA-1)을 Firebase Android 앱 `kr.mooca.petdate`에 등록:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
2. Google 제공자를 켠 뒤 `google-services.json`을 다시 받아 `android/app/google-services.json`을 교체합니다. `oauth_client`에 Android 클라이언트와 **web (`client_type: 3`)** 항목이 있어야 `google_sign_in`이 Android에서 `serverClientId`를 읽습니다.
3. Google Cloud에서 해당 OAuth 클라이언트의 패키지명/SHA-1이 맞는지 확인합니다.

### iOS — Google

현재 `ios/Runner/GoogleService-Info.plist`에는 `CLIENT_ID` / `REVERSED_CLIENT_ID`가 없습니다. Google 제공자를 켠 뒤 plist를 다시 받고:

1. `ios/Runner/GoogleService-Info.plist`를 교체합니다.
2. `ios/Runner/Info.plist`에 다음을 넣습니다 (`YOUR_…`는 새 plist 값):

```xml
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

3. 선택: `flutterfire configure`를 다시 돌려 `lib/firebase_options.dart`에 `iosClientId`가 생기게 합니다.

### Apple (iOS + Android)

저장소에는 `ios/Runner/Runner.entitlements`의 Sign in with Apple capability가 있습니다. 콘솔/애플 개발자 쪽은 직접 해야 합니다.

1. Apple Developer → Identifiers → App ID `kr.mooca.petdate`에 **Sign In with Apple** 활성화
2. Xcode에서 팀 서명과 capability가 프로비저닝 프로필에 포함되는지 확인
3. Firebase Authentication → Apple 제공자:
   - iOS: 서비스 ID 없이 네이티브 시트 (`FirebaseAuth.signInWithProvider`)
   - Android: Services ID + 리턴 URL `https://petdatinglove.firebaseapp.com/__/auth/handler` (Apple Services ID의 Return URL과 Firebase Apple 제공자 설정에 동일하게)
4. 반려견등록 인증은 소유주 이름·동물등록번호를 제출하면 수동 심사 후 Admin이 `verifiedAt`을 부여합니다. Auth 로그인 자체에는 포함되지 않습니다.

### 동작

- A01 Google / Apple → Firebase 사용자 생성·재사용 → `SessionNotifier` 계약 유지: `uid`, `isLoggedIn`, `phase`
- Firebase Auth가 모바일에서 세션을 유지합니다. 재실행 시 스플래시가 `users/{uid}` · `pets/{uid}`를 읽어 프로필 게이트를 건너뛸 수 있습니다.
- 로그아웃: 마이 화면 (`SessionNotifier.signOut()`).

Auth가 없으면 (위젯 테스트, 미설정 호스트) 탐색·좋아요·채팅은 **in-memory mock**으로 동작합니다. Auth가 있으면 Firestore 실경로입니다.

## A02 · likes / matches / chat (Firestore)

클라 경로는 `IdentityRemote.isLiveAuthReady`로 갈립니다.

| 단계 | 실연결 |
| --- | --- |
| 로그인 / 유저 문서 | `users/{uid}` ensure (`goal: friend`, `searchRadiusKm`, `createdAt`). **`verifiedAt` 클라 write 없음** |
| 프로필 완료 | `pets/{uid}` upsert. `petId == ownerId == uid` |
| A02 인증 | 소유주명·동물등록번호 제출 → `petRegStatus: pending` → 수동 확인 후 Admin이 `verifiedAt` 부여 → listen으로 해금 |
| 좋아요 | `likes/{fromUid}_{toPetId}`. `verifiedAt` 없으면 규칙 deny |
| 매칭 | 상호 좋아요 시 `matches/{minUid}_{maxUid}` + `threads/{matchId}` 배치 생성. `petIds` = 정렬된 uid |
| 채팅 | `threads/{matchId}/messages`, `meetProposals` |
| 차단·신고 | `blocks/{blockerId}_{blockedId}`, `reports` (클라 read 없음) |

컬렉션: `users` / `pets` / `likes` / `matches` / `threads` / `messages` / `meetProposals` / `blocks` / `reports` / `users/{uid}/fcmTokens`.

FCM 토큰은 클라가 `users/{uid}/fcmTokens/{sha256(token)}`에 upsert하고,
`onMessageCreated` / `onMatchCreated` / `onMeetProposalCreated` /
`onMeetProposalUpdated`가 Admin FCM으로 보냅니다. 계약은
[`functions/README.md`](functions/README.md) FCM 절을 따릅니다.

## 푸시 (P1) — 클라

알림 종류: **매칭 성공**, **새 메시지**, **만남 제안 수신**. 탭하면 `data.matchId`로 C02.
권한은 **첫 M01 매칭 직후**에만 묻고, 온보딩/가입 직후는 묻지 않습니다. 거절은 비블로킹.
미인증(`verifiedAt` 없음)이면 토큰을 쓰지 않습니다. Auth 없으면 no-op.
차단된 스레드는 C02에서 멤버 전용으로 막습니다. **`verifiedAt` 클라 write 없음.**

토큰 경로 (인프라 계약):

```
users/{uid}/fcmTokens/{tokenHash}
  tokenHash = sha256 hex of token (64 lowercase [a-f0-9])
  token: string 32–4096
  platform: 'ios' | 'android'
  updatedAt: serverTimestamp()
```

로그인 후(권한 허용된 경우) upsert, 로그아웃 시 같은 문서 delete.
페이로드: `{ type: match | message | meet_proposal, matchId }` (+ 제안 시 `proposalId`, `status`).

## 남은 콘솔 / 설정 체크리스트

코드만으로는 끝나지 않는 항목입니다. 프로젝트 `petdatinglove`.

### Authentication

- [ ] Sign-in method → **Google** on (지원 이메일)
- [ ] Sign-in method → **Apple** on
- [ ] 반려견등록 인증 제출 후 Admin이 `users/{uid}.verifiedAt`을 넣으면 좋아요가 해금되는지
- [ ] Android: debug/release/Play SHA-1을 `kr.mooca.petdate`에 등록 후 `google-services.json` 재다운로드 (`oauth_client` web `client_type: 3` 포함)
- [ ] iOS: Google 켠 뒤 `GoogleService-Info.plist` 재다운로드 → `CLIENT_ID` / `REVERSED_CLIENT_ID` → `Info.plist`의 `GIDClientID` + URL scheme
- [ ] Apple Developer App ID `kr.mooca.petdate` Sign In with Apple
- [ ] Android Apple: Services ID + Return URL `https://petdatinglove.firebaseapp.com/__/auth/handler`

### Firestore / Functions / Storage

- [ ] Firestore rules·indexes가 `petdatinglove`에 deploy되어 있는지 확인 (`firestore.rules`, `firestore.indexes.json`)
- [ ] Admin이 수동 심사 후 `users/{uid}.verifiedAt`을 넣거나 `markUserVerified` callable을 쓰는지
- [ ] `firebase deploy --only firestore:rules,functions` 후 message / match / meetProposal Functions가 `asia-northeast3`에 live
- [ ] Cloud Messaging 사용 + iOS APNs 키/인증서 업로드. Android `google-services.json`은 저장소에 있음
- [ ] 클라: 알림 권한 요청 후 owner-only `fcmTokens` upsert (`tokenHash` = sha256 hex, raw token을 doc id로 쓰지 않음)
- [ ] Blaze 플랜 (Functions 2nd gen)
- [ ] Storage 사진 업로드는 아직 deny-all. 펫 문서는 `pets/{uid}/photo_*` **경로 문자열**만 저장합니다. 미디어 PR 전까지 UI는 placeholder seed입니다.
- [ ] (선택) 탐색용 대략 위치: `pets.geohash` + `latlng` — 없으면 반경 필터 없이 목록

### APNs / FCM 콘솔 (푸시 P1)

코드만으로는 실기기 수신이 끝나지 않습니다. 프로젝트 `petdatinglove`.

- [ ] [Cloud Messaging](https://console.firebase.google.com/project/petdatinglove/settings/cloudmessaging) → **Cloud Messaging API (V1)** 사용 설정
- [ ] iOS: Apple Developer App ID `kr.mooca.petdate`에 **Push Notifications**
- [ ] iOS: Xcode Signing & Capabilities에 Push Notifications (저장소 `Runner.entitlements`의 `aps-environment`는 development — 배포 프로필은 production)
- [ ] iOS: APNs Authentication Key (`.p8`)를 Firebase Cloud Messaging에 업로드 (Key ID + Team ID)
- [ ] iOS: `GoogleService-Info.plist`가 최신 App ID와 맞는지
- [ ] Android: `android/app/google-services.json`이 `kr.mooca.petdate`와 맞는지
- [ ] Android 13+: `POST_NOTIFICATIONS` (매니페스트에 추가됨). 채널 id `banjjak_news` — 프로덕션 발송 전에 채널 생성
- [ ] Firestore rules deploy (`users/{uid}/fcmTokens/{sha256}` owner CRUD — #12)
- [ ] Functions live: `onMessageCreated` / `onMatchCreated` / `onMeetProposalCreated` / `onMeetProposalUpdated`
- [ ] 실기기: 첫 매칭(M01) → 「반짝 소식 받으실래요?」→ OS 다이얼로그 → 백그라운드 푸시 탭 → C02
- [ ] 실기기: 권한 거절 후에도 채팅 가능, Y01 설정 「알림 켜기」가 앱 알림 설정으로 이동

### App Check / 실기기

- [ ] 실기기에서 Google/Apple 로그인 → A02 → 좋아요가 `PERMISSION_DENIED` 없이 쓰이는지
- [ ] 미인증 계정으로 like create가 규칙에 막히는지
