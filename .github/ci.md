# CI for petdate (반짝산책)

GitHub Actions runs on pull requests and pushes to `main`. No Firebase
service-account secrets are required for this pipeline.

## Jobs

| Workflow | What it does |
| --- | --- |
| [CI](workflows/ci.yml) | Flutter **3.47.2** (Dart 3.13.2, matches `pubspec.yaml` `sdk: ^3.13.2`): `pub get`, `dart format` on `lib`/`test`, `flutter analyze`, `flutter test`. Pub dependencies are cached. |
| [Firestore rules](workflows/firestore-rules.yml) | Optional. Runs `@firebase/rules-unit-testing` against the **local** Firestore emulator. Triggers only when rules/test files change, or via **Actions → Firestore rules → Run workflow**. No secrets. |

Local equivalents:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

npm ci --prefix firebase/rules-tests
npx -y firebase-tools@latest emulators:exec --only firestore --project petdatinglove \
  "npm test --prefix firebase/rules-tests"
```

## Not in this pipeline (follow-up)

Internal / store builds are **not** signed or uploaded yet. A later deploy
workflow can add `workflow_dispatch` jobs that:

1. **Android** — `flutter build appbundle` (or APK) on `ubuntu-latest`, using
   Play upload keystore secrets (`ANDROID_KEYSTORE_BASE64`, `KEY_ALIAS`,
   passwords) and optionally Fastlane / Play Developer API for internal track.
2. **iOS** — `flutter build ipa` on `macos-latest`, using App Store Connect
   API key + signing certificate/provisioning profile secrets, then TestFlight
   internal.
3. Keep Firebase Auth/GoogleService files out of CI logs; still no need for a
   Firestore admin service account until Cloud Functions or rules deploy jobs.

Do not add those secrets until the signing workflow is reviewed.
