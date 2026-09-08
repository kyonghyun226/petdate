# Cloud Functions — 반짝산책 (`petdatinglove`)

Adult ID verification (product **A02**) records `users/{uid}.verifiedAt` here
via the Admin SDK. Firestore rules on `main` **deny** client create/update of
that field; likes and match creates require it to be a timestamp.

Do **not** write `verifiedAt` from Flutter. After the A02 verify UI succeeds
(mock or real vendor), call `markUserVerified`.

## Contract for 앱개발자 (A02)

| | |
| --- | --- |
| Name | `markUserVerified` |
| Type | HTTPS callable (2nd gen) |
| Region | `asia-northeast3` |
| Auth | Firebase Auth required (`request.auth.uid`) |
| Target | `users/{callerUid}` only |
| Write | `verifiedAt = FieldValue.serverTimestamp()` |
| Idempotent | If `verifiedAt` is already a timestamp, it is left unchanged |
| Success | `{ uid: string, verifiedAt: string }` (`verifiedAt` is ISO-8601 UTC) |

`users/{uid}` **must already exist** (goal, `searchRadiusKm`, `createdAt`).
The function uses Admin `update` and returns `failed-precondition` if the
doc is missing. Creating a stub with only `verifiedAt` would block the
client's later profile create.

If A02 UI runs before the first user-doc write (O01 / profile): keep a
local “passed verify” flag and call this **after** `users/{uid}` is created.

Passing another user's `uid` in the payload is **denied**. The write always
uses the Auth token uid.

### Flutter (after A02 success)

Add `cloud_functions` next to the existing Firebase packages, then:

```dart
import 'package:cloud_functions/cloud_functions.dart';

/// Call only after the A02 verify UI succeeds.
/// Never write users/{uid}.verifiedAt from the client.
Future<({String uid, DateTime verifiedAt})> completeIdVerification() async {
  final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast3')
      .httpsCallable('markUserVerified');
  final result = await callable.call();
  final data = Map<String, dynamic>.from(result.data as Map);
  return (
    uid: data['uid'] as String,
    verifiedAt: DateTime.parse(data['verifiedAt'] as String),
  );
}
```

Local emulator (optional):

```dart
FirebaseFunctions.instanceFor(region: 'asia-northeast3')
    .useFunctionsEmulator('localhost', 5001);
```

Unhandled callable errors to expect:

| Code | When |
| --- | --- |
| `unauthenticated` | No Firebase Auth session |
| `permission-denied` | Payload `uid` is not the caller |
| `failed-precondition` | `users/{uid}` does not exist yet |

## Deploy

Cloud Functions (2nd gen) need the **Blaze** (pay-as-you-go) plan. Spark
cannot deploy callables. A `petdatinglove` owner should confirm billing,
then:

```bash
npx -y firebase-tools@latest login
npx -y firebase-tools@latest use petdatinglove
npm ci --prefix functions
npx -y firebase-tools@latest deploy --only functions
```

That deploys `markUserVerified` to `asia-northeast3`. First-time Blaze
setup: Firebase console → Upgrade → Blaze. Usage for this single callable
is typically within the free quota.

This repo does **not** auto-deploy functions (no service-account CI).

## FCM push (P1) — contract for 앱개발자

Client **registers** tokens. Infra **sends**. Do not use the raw FCM
token as the Firestore document id.

### Token storage

| | |
| --- | --- |
| Path | `users/{uid}/fcmTokens/{tokenHash}` |
| `tokenHash` | sha256 hex of `token` (64 lowercase `[a-f0-9]`) |
| Fields | `token` (string 32–4096), `platform` (`ios` \| `android`), `updatedAt` (`FieldValue.serverTimestamp()`) |
| Rules | Owner create / update / delete / read only. Peers cannot read another user's tokens. |

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String fcmTokenHash(String token) =>
    sha256.convert(utf8.encode(token)).toString();

Future<void> upsertFcmToken({
  required String uid,
  required String token,
  required String platform, // 'ios' | 'android'
}) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('fcmTokens')
      .doc(fcmTokenHash(token))
      .set({
    'token': token,
    'platform': platform,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

Delete the same doc on logout / token refresh. Request OS notification
permission before registering.

### Send Functions (Admin FCM, `asia-northeast3`)

| Name | Trigger | Recipients | Notification | Data |
| --- | --- | --- | --- | --- |
| `onMessageCreated` | `threads/{matchId}/messages/{messageId}` create | match `userIds` except `senderId` | title `반짝산책` / body `새 메시지가 도착했어요` | `matchId`, `type: message` |
| `onMatchCreated` | `matches/{matchId}` create | both `userIds` (once each) | title `반짝산책` / body `산책 메이트와 연결됐어요` | `matchId`, `type: match` |

Copy is walk-mate tone (not dating). Message text is **not** included.
Stale tokens (`unregistered` / `invalid-registration-token`) are deleted.
`meetProposals` fan-out is stubbed for a later PR.

### Console checklist (cannot be done from this repo)

1. Firebase console → Cloud Messaging: enable FCM for `petdatinglove`.
2. **iOS:** upload an APNs auth key (or certificate) on the Cloud Messaging
   settings page. The app must have the Push Notifications capability.
3. **Android:** `android/app/google-services.json` is already in the repo
   (`kr.mooca.petdate`). Confirm the Android app exists in the same project.
4. Client must request notification permission (iOS + Android 13+) and
   upsert the token at the path above.

### Deploy (rules + functions together)

```bash
npx -y firebase-tools@latest login
npx -y firebase-tools@latest use petdatinglove
npm ci --prefix functions
npx -y firebase-tools@latest deploy --only firestore:rules,functions
```

## Local build / test

```bash
npm ci --prefix functions
npm test --prefix functions
npm run build --prefix functions

# Optional: Admin write against the Firestore emulator
npm run test:emulator --prefix functions
```

```bash
npx -y firebase-tools@latest emulators:start \
  --only functions,firestore --project petdatinglove
```

## ID vendor (later)

The Korean provider (PASS / NICE / KCB / …) is **stubbed**. When a webhook
exists, verify the vendor signature, map the session to a Firebase uid, and
call `setVerifiedAtForUid` in `src/verifiedAt.ts`. Do not let the client
write `verifiedAt`, and do not expose an unauthenticated “set uid” HTTP
endpoint.
