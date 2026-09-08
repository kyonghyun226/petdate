import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/app.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';

void main() {
  testWidgets('splash shows brand then onboarding copy', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PetdateApp()));

    expect(find.text(AppCopy.appName), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('우리 반려도 친구가 필요해요'), findsOneWidget);
    expect(find.text(AppCopy.onboardingStart), findsNothing);
    expect(find.text(AppCopy.next), findsOneWidget);
  });

  testWidgets('onboarding to login to goal to wizard to home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PetdateApp()));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.next));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.next));
    await tester.pumpAndSettle();
    expect(find.text('산책·카페에서 자연스럽게 만나요'), findsOneWidget);

    await tester.tap(find.text(AppCopy.onboardingStart));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.loginTitle), findsOneWidget);
    expect(find.text(AppCopy.loginGoogle), findsOneWidget);
    expect(find.text(AppCopy.loginApple), findsOneWidget);

    await tester.tap(find.text(AppCopy.loginGoogle));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.goalQuestion), findsOneWidget);
    expect(find.text(AppCopy.next), findsOneWidget);

    await tester.tap(find.text(AppCopy.goalFriendTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.next));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.p01Title), findsOneWidget);
  });

  testWidgets('already have account skips to login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PetdateApp()));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.loginTitle), findsOneWidget);
  });

  testWidgets('light theme uses v0.4 tokens not cream or deepPurple',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PetdateApp()));
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme!.scaffoldBackgroundColor, AppColors.bg);
    expect(materialApp.theme!.colorScheme.primary, AppColors.primary);
    expect(AppColors.bg, const Color(0xFFFFFFFF));
    expect(AppColors.primary, const Color(0xFFFF6B4A));
  });

  testWidgets('profile wizard validation then start to home', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: PetdateApp()));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.loginApple));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.goalWalkTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.next));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.p01Title), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, AppCopy.next)).onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), '초코');
    await tester.tap(find.text(AppCopy.speciesDog));
    await tester.enterText(find.byType(TextField).at(1), '말티즈');
    await tester.enterText(find.byType(TextField).at(2), '3');
    await tester.tap(find.text(AppCopy.genderMale));
    await tester.tap(find.text(AppCopy.sizeSmall));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, AppCopy.next)).onPressed, isNotNull);

    await tester.tap(find.text(AppCopy.next));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.photoGuide), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined).first);
    await tester.pump();
    await tester.tap(find.text(AppCopy.next));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.p03Title), findsOneWidget);

    await tester.tap(find.text(AppCopy.petTags[0]));
    await tester.tap(find.text(AppCopy.petTags[1]));
    await tester.tap(find.text(AppCopy.petTags[2]));
    await tester.pump();
    await tester.tap(find.text(AppCopy.next));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.p04Title), findsOneWidget);
    expect(find.text(GoalCopy.bioPlaceholder(UserGoal.walk)), findsOneWidget);

    await tester.tap(find.text(AppCopy.startSpark));
    await tester.pumpAndSettle();
    expect(find.text(GoalCopy.homeTitle(UserGoal.walk)), findsOneWidget);
    expect(find.text(AppCopy.navHome), findsOneWidget);
    expect(find.text(AppCopy.navMy), findsOneWidget);
  });

  testWidgets('main shell bottom nav after mocked completed session',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).completeSplash();
    container.read(sessionProvider.notifier).completeOnboarding();
    container.read(sessionProvider.notifier).mockLogin();
    container.read(sessionProvider.notifier).setGoal(UserGoal.walk);
    container.read(sessionProvider.notifier).confirmGoal();
    container.read(sessionProvider.notifier).completeProfile();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PetdateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(GoalCopy.homeTitle(UserGoal.walk)), findsOneWidget);
    expect(find.text(GoalCopy.homeEmpty(UserGoal.walk)), findsOneWidget);
    expect(find.text(AppCopy.navHome), findsOneWidget);
    expect(find.text(AppCopy.navSpark), findsOneWidget);

    await tester.tap(find.text(AppCopy.navSpark));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.sparkEmpty), findsOneWidget);
  });
}
