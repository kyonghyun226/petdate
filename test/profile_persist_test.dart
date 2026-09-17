import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_app.dart';

void main() {
  test('hydrated profile survives splash login tick', () {
    final container = testContainer(
      auth: FakeAuthRepository(
        signedInUser: const AuthUser(uid: 'returning', providerId: 'password'),
      ),
    );
    addTearDown(container.dispose);

    // Warm the draft provider while logged out (tick == 0).
    expect(container.read(profileDraftProvider).petName, isEmpty);

    container.read(profileDraftProvider.notifier).hydrate(
          const ProfileDraft(petName: '뽀삐', breed: '푸들'),
        );
    expect(container.read(profileDraftProvider).petName, '뽀삐');

    // Returning Auth session flips isLoggedIn — must not wipe the draft.
    container.read(sessionProvider.notifier).completeSplash(
          remoteProfileCompleted: true,
        );

    expect(container.read(sessionProvider).isLoggedIn, isTrue);
    expect(container.read(profileDraftProvider).petName, '뽀삐');
    expect(container.read(profileDraftProvider).breed, '푸들');
  });

  test('logout clears the profile draft', () {
    final container = testContainer();
    addTearDown(container.dispose);

    seedCompletedSession(container);
    container.read(profileDraftProvider.notifier).hydrate(
          const ProfileDraft(petName: '뽀삐'),
        );
    expect(container.read(profileDraftProvider).petName, '뽀삐');

    container.read(sessionProvider.notifier).logout();

    expect(container.read(profileDraftProvider).petName, isEmpty);
  });
}
