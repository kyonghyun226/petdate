import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/data/backend_mode.dart';
import 'package:petdate/data/mock_social_repository.dart';
import 'package:petdate/data/social_repository.dart';
import 'package:petdate/firebase/firestore_social_repository.dart';
import 'package:petdate/firebase/identity_remote.dart';

/// Explore / spark / chat. May be mock for review-demo catalog.
final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  if (ref.watch(useMockDataProvider)) {
    final repo = MockSocialRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return FirestoreSocialRepository();
});

/// Signed-in user's pet card. Always Firestore when Auth is live — even if
/// the feed catalog is mock for App Store review accounts.
final ownPetRepositoryProvider = Provider<SocialRepository>((ref) {
  ref.watch(authStateChangesProvider);
  if (IdentityRemote.isLiveAuthReady) {
    return FirestoreSocialRepository();
  }
  return ref.watch(socialRepositoryProvider);
});
