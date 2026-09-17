import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/data/demo_mode.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/state/session_provider.dart';

/// True when home / spark / chat should use the in-memory MockCatalog.
///
/// Does **not** control own-pet persistence — see [ownPetUsesFirestore].
final demoCatalogActiveProvider = Provider<bool>((ref) {
  if (DemoMode.enabled) return true;
  final uid = ref.watch(sessionProvider.select((s) => s.uid));
  // Guest preview (no Auth) uses [DemoMode.uid] + MockCatalog.
  if (uid == DemoMode.uid) return true;
  final email = ref.watch(currentAuthUserProvider.select((u) => u?.email));
  return DemoMode.isReviewDemoAccount(uid: uid, email: email);
});

/// Auth 없으면 mock. Review-demo catalog도 mock 피드.
///
/// Override this provider in tests to force mock even if Auth is present.
/// Own pet create/update must **not** use this — use [ownPetUsesFirestore]
/// / `ownPetRepositoryProvider` so profiles persist to Firestore.
final useMockDataProvider = Provider<bool>((ref) {
  ref.watch(authStateChangesProvider);
  if (ref.watch(demoCatalogActiveProvider)) return true;
  return !IdentityRemote.isLiveAuthReady;
});

/// Own `pets/{uid}` / profile writes when Firebase Auth has a user.
bool get ownPetUsesFirestore => IdentityRemote.isLiveAuthReady;
