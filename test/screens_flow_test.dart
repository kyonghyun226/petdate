import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/app.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';

ProviderContainer _loggedIn({UserGoal goal = UserGoal.friend}) {
  final container = ProviderContainer();
  final session = container.read(sessionProvider.notifier);
  session.completeSplash();
  session.completeOnboarding();
  session.mockLogin();
  session.setGoal(goal);
  session.confirmGoal();
  session.completeProfile();
  return container;
}

Future<void> _pumpMain(
  WidgetTester tester,
  ProviderContainer container,
) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const PetdateApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('H01 shows stack then empty after passing all', (tester) async {
    final container = _loggedIn(goal: UserGoal.walk);
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    expect(find.text(GoalCopy.homeTitle(UserGoal.walk)), findsOneWidget);
    expect(find.textContaining('콩이'), findsWidgets);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('pass-button')));
      await tester.pumpAndSettle();
    }

    expect(find.text(GoalCopy.homeEmpty(UserGoal.walk)), findsOneWidget);
    expect(find.text(AppCopy.refresh), findsOneWidget);

    await tester.tap(find.text(AppCopy.refresh));
    await tester.pumpAndSettle();
    expect(find.textContaining('콩이'), findsWidgets);
  });

  testWidgets('H01 tap opens D01 and CTA matches', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    await tester.tap(find.byKey(const ValueKey('home-card-kong')));
    await tester.pumpAndSettle();
    expect(find.text(GoalCopy.detailCta(UserGoal.friend, '콩이')), findsOneWidget);
    expect(find.text('꼬리부터 반짝하는 말티즈예요. 공원에서 친구 만드는 중!'), findsOneWidget);

    await tester.tap(find.byTooltip(AppCopy.reportMenu));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.reportTitle), findsOneWidget);
    await tester.tap(find.text(AppCopy.close));
    await tester.pumpAndSettle();
  });

  testWidgets('mutual like opens M01 then C02 with chips', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.matchTitle), findsOneWidget);
    expect(find.text(AppCopy.safetyBanner), findsOneWidget);
    expect(find.text(AppCopy.startChat), findsOneWidget);

    await tester.tap(find.text(AppCopy.startChat));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.chatSystemMatch), findsOneWidget);
    expect(find.text(AppCopy.proposeMeetup), findsOneWidget);
    expect(
      find.text(GoalCopy.firstMessageChips(UserGoal.friend, AppCopy.fallbackPetName).first),
      findsOneWidget,
    );

    await tester.tap(
      find.text(GoalCopy.firstMessageChips(UserGoal.friend, AppCopy.fallbackPetName).first),
    );
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      GoalCopy.firstMessageChips(UserGoal.friend, AppCopy.fallbackPetName).first,
    );
    expect(find.text(AppCopy.chatSystemMatch), findsOneWidget);

    await tester.tap(find.text(AppCopy.proposeMeetup));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.meetupPlace), findsOneWidget);
    await tester.tap(find.text(AppCopy.send));
    await tester.pumpAndSettle();
    expect(find.textContaining('만남 제안'), findsWidgets);
  });

  testWidgets('C01 empty goes home; B01 matched opens chat', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    await tester.tap(find.text(AppCopy.navChat));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.chatEmpty), findsOneWidget);
    await tester.tap(find.text(AppCopy.goHome));
    await tester.pumpAndSettle();
    expect(find.text(GoalCopy.homeTitle(UserGoal.friend)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.later));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.navSpark));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.sparkMatched));
    await tester.pumpAndSettle();
    expect(find.textContaining('콩이'), findsWidgets);
    await tester.tap(find.textContaining('콩이').first);
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.chatSystemMatch), findsOneWidget);
  });

  testWidgets('Y01 summary, goal change and logout', (tester) async {
    final container = _loggedIn(goal: UserGoal.friend);
    addTearDown(container.dispose);
    container.read(profileDraftProvider.notifier).setPetName('초코');
    await _pumpMain(tester, container);

    await tester.tap(find.text(AppCopy.navMy));
    await tester.pumpAndSettle();
    expect(find.text('초코'), findsOneWidget);
    expect(find.text(AppCopy.myChangeGoal), findsOneWidget);

    await tester.tap(find.text(AppCopy.myChangeGoal));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.goalWalkTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.goalApply));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.navHome));
    await tester.pumpAndSettle();
    expect(find.text(GoalCopy.homeTitle(UserGoal.walk)), findsOneWidget);

    await tester.tap(find.text(AppCopy.navMy));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.myLogout));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.loginTitle), findsOneWidget);
  });

  test('P03 requires 3-8 tags and 1-3 time slots', () {
    const draft = ProfileDraft();
    expect(draft.p03Valid, isFalse);
    final tagged = draft.copyWith(
      tags: {'walk_lover', 'cafe_lover', 'park_lover'},
    );
    expect(tagged.p03TagsValid, isTrue);
    expect(tagged.p03Valid, isFalse);
    final ready = tagged.copyWith(
      preferredTimeSlots: {PreferredTimeSlot.weekendMorning},
    );
    expect(ready.p03Valid, isTrue);
  });
}
