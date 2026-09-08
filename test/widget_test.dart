import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/theme/brand_assets.dart';
import 'package:petdate/theme/tokens.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('splash shows brand then onboarding copy', (tester) async {
    await tester.pumpWidget(testApp());

    expect(find.bySemanticsLabel(AppCopy.appName), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) => w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == BrandAssets.appIcon,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == BrandAssets.wordmark,
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.onboardingPages[0].title), findsOneWidget);
    expect(find.text(AppCopy.onboardingPages[0].body), findsOneWidget);
    expect(find.text(AppCopy.onboardingStart), findsNothing);
    expect(find.text(AppCopy.next), findsOneWidget);
  });

  testWidgets('onboarding to login to goal to wizard to home', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.next));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.next));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.onboardingPages[2].title), findsOneWidget);
    expect(find.text(AppCopy.onboardingPages[2].body), findsOneWidget);

    await tester.tap(find.text(AppCopy.onboardingStart));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.loginTitle), findsOneWidget);
    expect(find.text(AppCopy.loginGoogle), findsOneWidget);
    expect(find.text(AppCopy.loginApple), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == BrandAssets.appIcon,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == BrandAssets.wordmark,
      ),
      findsOneWidget,
    );

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
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.loginTitle), findsOneWidget);
  });

  testWidgets('light theme uses v0.4 tokens not cream or deepPurple',
      (tester) async {
    await tester.pumpWidget(testApp());
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

    await tester.pumpWidget(testApp());
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

    await tester.tap(find.text(AppCopy.petTags[0].label));
    await tester.tap(find.text(AppCopy.petTags[1].label));
    await tester.tap(find.text(AppCopy.petTags[2].label));
    await tester.tap(find.text('평일 저녁'));
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
    final container = testContainer();
    addTearDown(container.dispose);
    seedCompletedSession(container, goal: UserGoal.walk);

    await tester.pumpWidget(testApp(container: container));
    await tester.pumpAndSettle();

    expect(find.text(GoalCopy.homeTitle(UserGoal.walk)), findsOneWidget);
    expect(find.textContaining('콩이'), findsWidgets);
    expect(find.text(AppCopy.navHome), findsOneWidget);
    expect(find.text(AppCopy.navSpark), findsOneWidget);

    await tester.tap(find.text(AppCopy.navSpark));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.sparkReceived), findsOneWidget);
    expect(find.text(AppCopy.sparkEmpty), findsNothing);
  });

  test('store listing copy constants', () {
    expect(AppCopy.appName, '반짝산책');
    expect(AppCopy.storeSubtitle, '반려 친구 · 산책 메이트 찾기');
    expect(
      AppCopy.storeTagline,
      '우리 반려의 짝을 찾아요. 친구 사귀기부터 같이 산책하기까지.',
    );
    expect(AppCopy.onboardingPages, hasLength(3));
    expect(AppCopy.onboardingPages[1].title, '친구 사귀기 · 같이 산책하기');
    expect(AppCopy.onboardingPages[1].body,
      '원하는 목적만 고르면, 라이프스타일이 맞는 견주·묘주를 추천해 드려요.',
    );
    expect(AppCopy.petTags, hasLength(12));
    expect(AppCopy.petTags.last.key, 'travel_mate');
    expect(AppCopy.petTags.last.label, '여행 메이트');
    expect(AppConstants.searchRadiusKm, 5);
    expect(AppColors.safetyBg, const Color(0xFFE8F7F3));
    expect(AppColors.safetyText, const Color(0xFF2F6F62));
    expect(BrandAssets.appIcon, 'assets/branding/app_icon.png');
    expect(BrandAssets.wordmark, 'assets/branding/wordmark_v3.png');
    expect(BrandAssets.hasWordmarkImage, isTrue);
    expect(BrandAssets.wordmarkHalfSpark, '반짝');
    expect(BrandAssets.wordmarkHalfWalk, '산책');
  });
}
