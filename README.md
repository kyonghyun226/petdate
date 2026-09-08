# 반짝산책 (petdate)

반려 친구 · 산책 메이트 찾기. Flutter 앱, Firebase 프로젝트 `petdatinglove`.

Adult ID verification (`users/{uid}.verifiedAt`) is written only by the
`markUserVerified` Cloud Function. See [`functions/README.md`](functions/README.md).

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
4. 성인 본인인증은 `markUserVerified`로 이어지며, Auth 로그인 자체에는 포함되지 않습니다.

### 동작

- A01 Google / Apple → Firebase 사용자 생성·재사용 → `isLoggedIn` + `phase: goal`
- Firebase Auth가 모바일에서 세션을 유지합니다. 재실행 시 스플래시 후 로그인을 건너뛰고, 아직 없는 목적/프로필 게이트는 그대로입니다.
- 로그아웃: 마이 화면 (`SessionNotifier.signOut()`).
