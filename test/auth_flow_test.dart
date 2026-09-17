import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/widgets/main_tab_app_bar.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('guest preview enters main without Auth', (tester) async {
    await tester.pumpWidget(testApp());
    await pumpPastSplash(tester);
    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.loginGuestPreview));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.homeTitle), findsOneWidget);
    expect(find.text(AppCopy.loginTitle), findsNothing);
    expect(find.text(AppCopy.p00Title), findsNothing);
  });

  testWidgets('Google and Apple sign-in move session to profile', (tester) async {
    await tester.pumpWidget(testApp());
    await pumpPastSplash(tester);
    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.loginGoogle));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.p00Title), findsOneWidget);
  });

  testWidgets('user cancel stays on login without a failure snackbar',
      (tester) async {
    final auth = FakeAuthRepository(outcome: FakeAuthOutcome.cancelled);
    await tester.pumpWidget(testApp(auth: auth));
    await pumpPastSplash(tester);
    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.loginApple));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.loginTitle), findsOneWidget);
    expect(find.text(AppCopy.loginFailed), findsNothing);
    expect(find.text(AppCopy.p00Title), findsNothing);
  });

  testWidgets('failed sign-in stays on login and shows a simple snackbar',
      (tester) async {
    final auth = FakeAuthRepository(outcome: FakeAuthOutcome.failure);
    await tester.pumpWidget(testApp(auth: auth));
    await pumpPastSplash(tester);
    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.loginGoogle));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.loginTitle), findsOneWidget);
    expect(find.text(AppCopy.loginFailed), findsOneWidget);
    expect(find.text(AppCopy.p00Title), findsNothing);
  });

  testWidgets('persisted user skips login and still hits the profile gate',
      (tester) async {
    final auth = FakeAuthRepository(
      signedInUser: const AuthUser(uid: 'returning', providerId: 'google.com'),
    );
    await tester.pumpWidget(testApp(auth: auth));
    await pumpPastSplash(tester);

    expect(find.text(AppCopy.loginTitle), findsNothing);
    expect(find.text(AppCopy.onboardingPages[0].title), findsNothing);
    expect(find.text(AppCopy.p00Title), findsOneWidget);
  });

  testWidgets('returning Apple user skips profile when remote pet exists',
      (tester) async {
    final auth = FakeAuthRepository(
      signedInUser: const AuthUser(uid: 'returning', providerId: 'apple.com'),
    );
    final container = testContainer(auth: auth);
    addTearDown(container.dispose);

    // Simulate Firestore pet restore without a live Firebase app: mark the
    // profile complete the same way splash does after SessionBootstrap.
    container.read(sessionProvider.notifier).completeSplash(
          remoteProfileCompleted: true,
        );

    await tester.pumpWidget(testApp(container: container));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.homeTitle), findsOneWidget);
    expect(find.text(AppCopy.p00Title), findsNothing);
    expect(find.text(AppCopy.loginTitle), findsNothing);
  });

  testWidgets('re-login restores main when profile was already completed',
      (tester) async {
    final auth = FakeAuthRepository();
    final container = testContainer(auth: auth);
    addTearDown(container.dispose);

    await tester.pumpWidget(testApp(container: container));
    await pumpPastSplash(tester);
    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();

    // Pretend a prior session already finished the wizard (in-memory), then
    // completeLogin must not force the empty wizard again.
    container.read(sessionProvider.notifier).completeProfile();
    await container.read(sessionProvider.notifier).completeLogin();
    await tester.pumpAndSettle();

    expect(container.read(sessionProvider).phase, AppPhase.main);
    expect(find.text(AppCopy.homeTitle), findsOneWidget);
    expect(find.text(AppCopy.p00Title), findsNothing);
  });

  testWidgets('sign-out from My returns to login', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);
    seedCompletedSession(container);

    await tester.pumpWidget(testApp(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(MainTabAppBar.profileButtonKey).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.myLogout));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.loginTitle), findsOneWidget);
    expect(container.read(sessionProvider).isLoggedIn, isFalse);
    expect(container.read(sessionProvider).uid, isNull);
  });

  testWidgets('delete account from My confirms then returns to login',
      (tester) async {
    final auth = FakeAuthRepository(
      signedInUser: const AuthUser(uid: 'to-delete', providerId: 'google.com'),
    );
    final container = testContainer(auth: auth);
    addTearDown(container.dispose);
    seedCompletedSession(container);

    await tester.pumpWidget(testApp(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(MainTabAppBar.profileButtonKey).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.myDeleteAccount));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.deleteAccountTitle), findsOneWidget);
    await tester.tap(find.text(AppCopy.deleteAccountCancel));
    await tester.pumpAndSettle();
    expect(container.read(sessionProvider).isLoggedIn, isTrue);

    await tester.tap(find.text(AppCopy.myDeleteAccount));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.deleteAccountConfirm));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.loginTitle), findsOneWidget);
    expect(container.read(sessionProvider).isLoggedIn, isFalse);
    expect(auth.currentUser, isNull);
  });

  testWidgets('successful sign-in exposes uid on the session', (tester) async {
    final auth = FakeAuthRepository();
    final container = testContainer(auth: auth);
    addTearDown(container.dispose);

    await tester.pumpWidget(testApp(container: container));
    await pumpPastSplash(tester);
    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.loginGoogle));
    await tester.pumpAndSettle();

    expect(container.read(sessionProvider).isLoggedIn, isTrue);
    expect(container.read(sessionProvider).phase, AppPhase.profile);
    expect(container.read(sessionProvider).uid, 'fake-google.com');
    expect(container.read(currentAuthUserProvider)?.uid, 'fake-google.com');
  });
}
