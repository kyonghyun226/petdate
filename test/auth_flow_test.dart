import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/session_provider.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('Google and Apple sign-in move session to goal', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.loginGoogle));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.goalQuestion), findsOneWidget);
  });

  testWidgets('user cancel stays on login without a failure snackbar',
      (tester) async {
    final auth = FakeAuthRepository(outcome: FakeAuthOutcome.cancelled);
    await tester.pumpWidget(testApp(auth: auth));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.loginApple));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.loginTitle), findsOneWidget);
    expect(find.text(AppCopy.loginFailed), findsNothing);
    expect(find.text(AppCopy.goalQuestion), findsNothing);
  });

  testWidgets('failed sign-in stays on login and shows a simple snackbar',
      (tester) async {
    final auth = FakeAuthRepository(outcome: FakeAuthOutcome.failure);
    await tester.pumpWidget(testApp(auth: auth));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.loginGoogle));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.loginTitle), findsOneWidget);
    expect(find.text(AppCopy.loginFailed), findsOneWidget);
    expect(find.text(AppCopy.goalQuestion), findsNothing);
  });

  testWidgets('persisted user skips login and still hits the goal gate',
      (tester) async {
    final auth = FakeAuthRepository(
      signedInUser: const AuthUser(uid: 'returning', providerId: 'google.com'),
    );
    await tester.pumpWidget(testApp(auth: auth));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.loginTitle), findsNothing);
    expect(find.text(AppCopy.onboardingPages[0].title), findsNothing);
    expect(find.text(AppCopy.goalQuestion), findsOneWidget);
  });

  testWidgets('returning user with a completed profile lands in main',
      (tester) async {
    final auth = FakeAuthRepository(
      signedInUser: const AuthUser(uid: 'returning', providerId: 'apple.com'),
    );
    final container = testContainer(auth: auth);
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).setGoal(UserGoal.walk);
    container.read(sessionProvider.notifier).completeProfile();
    container.read(sessionProvider.notifier).completeSplash();

    await tester.pumpWidget(testApp(container: container));
    await tester.pumpAndSettle();

    expect(find.text(GoalCopy.homeTitle(UserGoal.walk)), findsOneWidget);
    expect(find.text(AppCopy.loginTitle), findsNothing);
  });

  testWidgets('sign-out from My returns to login', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);
    seedCompletedSession(container, goal: UserGoal.friend);

    await tester.pumpWidget(testApp(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.navMy));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.myLogout));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.loginTitle), findsOneWidget);
    expect(container.read(sessionProvider).isLoggedIn, isFalse);
    expect(container.read(sessionProvider).uid, isNull);
  });

  testWidgets('successful sign-in exposes uid on the session', (tester) async {
    final auth = FakeAuthRepository();
    final container = testContainer(auth: auth);
    addTearDown(container.dispose);

    await tester.pumpWidget(testApp(container: container));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.loginGoogle));
    await tester.pumpAndSettle();

    expect(container.read(sessionProvider).isLoggedIn, isTrue);
    expect(container.read(sessionProvider).phase, AppPhase.goal);
    expect(container.read(sessionProvider).uid, 'fake-google.com');
    expect(container.read(currentAuthUserProvider)?.uid, 'fake-google.com');
  });
}
