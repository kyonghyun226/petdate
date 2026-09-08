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
