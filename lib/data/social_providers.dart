import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/data/backend_mode.dart';
import 'package:petdate/data/mock_social_repository.dart';
import 'package:petdate/data/social_repository.dart';
import 'package:petdate/firebase/firestore_social_repository.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  if (ref.watch(useMockDataProvider)) {
    final repo = MockSocialRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return FirestoreSocialRepository();
});
