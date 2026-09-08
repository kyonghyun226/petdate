# CI for petdate (반짝산책)

GitHub Actions runs on pull requests and pushes to `main`. No Firebase
service-account secrets are required for this pipeline.

## Jobs

| Workflow | What it does |
| --- | --- |
| [CI](workflows/ci.yml) | Flutter **3.47.2** (Dart 3.13.2, matches `pubspec.yaml` `sdk: ^3.13.2`): `pub get`, advisory `dart format` on `lib`/`test` (**non-blocking**), required `flutter analyze` and `flutter test`. Pub dependencies are cached. |
| [Firestore rules](workflows/firestore-rules.yml) | Optional. Runs `@firebase/rules-unit-testing` against the **local** Firestore emulator. Triggers only when rules/test files change, or via **Actions → Firestore rules → Run workflow**. No secrets. |
| [Functions](workflows/functions.yml) | `npm ci` / `npm test` / `npm run build` in `functions/`. Triggers when functions files change. No secrets; **does not deploy**. |

## Local equivalents

Required gates (same as CI):

```bash
flutter pub get
flutter analyze
flutter test
```

Format is **advisory** in CI (`continue-on-error`). Several existing `lib`/`test` files on `main` are not `dart format` clean; mass-formatting them now would collide with open PRs **#2** (UI) and **#3** (Auth). After those land (or in a dedicated format-only PR), re-enable a hard fail by removing `continue-on-error` from the format step in `workflows/ci.yml`.

Until then, inspect drift locally without rewriting files:

```bash
dart format --output=none --set-exit-if-changed lib test
```

Firestore rules (optional; needs the emulator, no secrets):

```bash
npm ci --prefix firebase/rules-tests
npx -y firebase-tools@latest emulators:exec --only firestore --project petdatinglove \
  "npm test --prefix firebase/rules-tests"
```

Cloud Functions (no deploy):

```bash
npm ci --prefix functions
npm test --prefix functions
npm run build --prefix functions
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
3. Keep Firebase Auth/GoogleService files out of CI logs. Functions **code**
   is typechecked here; `firebase deploy --only functions` is still a
   manual Blaze-plan step (see `functions/README.md`).

Do not add those secrets until the signing workflow is reviewed.
