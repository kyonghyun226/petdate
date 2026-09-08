import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/app.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/pet_tag.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/copy/species_copy.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/state/analytics_provider.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';

import 'helpers/fake_auth_repository.dart';

ProviderContainer _loggedIn({
  UserGoal goal = UserGoal.friend,
  bool verified = true,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith(
        (ref) => FakeAuthRepository(
          signedInUser: const AuthUser(uid: 'mock_uid', providerId: 'google.com'),
        ),
      ),
    ],
  );
  final session = container.read(sessionProvider.notifier);
  session.completeSplash();
  session.completeOnboarding();
  session.completeLogin();
  session.setGoal(goal);
  session.confirmGoal();
  session.completeProfile();
  if (verified) {
    container.read(userDocProvider.notifier).ingestListenSnapshot(
          verifiedAt: DateTime.utc(2026, 9, 8),
        );
  }
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
    expect(find.byKey(const ValueKey('home-card-kong')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-card-bori')), findsNothing);

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

  testWidgets('H01 and D01 like CTAs use sparkle not heart or paw',
      (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    final like = find.byKey(const ValueKey('like-button'));
    expect(
      find.descendant(of: like, matching: find.byIcon(AppIcons.spark)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: like, matching: find.byIcon(Icons.favorite)),
      findsNothing,
    );
    expect(
      find.descendant(of: like, matching: find.byIcon(Icons.favorite_rounded)),
      findsNothing,
    );
    expect(
      find.descendant(of: like, matching: find.byIcon(Icons.pets)),
      findsNothing,
    );
    expect(
      find.descendant(of: like, matching: find.byIcon(Icons.pets_rounded)),
      findsNothing,
    );

    final passMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const ValueKey('pass-button')),
        matching: find.byType(Material),
      ).first,
    );
    final passShape = passMaterial.shape as CircleBorder;
    expect(passShape.side.color, AppColors.border);
    expect(passShape.side.width, 1.5);

    await tester.tap(find.byKey(const ValueKey('home-card-kong')));
    await tester.pumpAndSettle();
    final d01 = find.byKey(const ValueKey('d01-cta'));
    expect(
      find.descendant(of: d01, matching: find.byIcon(AppIcons.spark)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: d01, matching: find.byIcon(Icons.favorite)),
      findsNothing,
    );
    expect(
      find.descendant(of: d01, matching: find.byIcon(Icons.pets)),
      findsNothing,
    );
    expect(
      find.descendant(of: d01, matching: find.byIcon(Icons.pets_rounded)),
      findsNothing,
    );
  });

  testWidgets('H01 tap opens D01 and CTA matches', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    await tester.tap(find.byKey(const ValueKey('home-card-kong')));
    await tester.pumpAndSettle();
    expect(find.text(GoalCopy.detailCta(UserGoal.friend, '콩이')), findsOneWidget);
    expect(find.textContaining(AppCopy.petNounDog), findsOneWidget);
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
    expect(
      container.read(analyticsProvider).events,
      contains(MeetKpi.proposalSent),
    );
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
    expect(find.byKey(const ValueKey('spark-row-kong')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('spark-row-kong')));
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

  testWidgets('D01 sticky CTA opens M01 then C03', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    await tester.tap(find.byKey(const ValueKey('home-card-kong')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('d01-cta')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('d01-cta')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.matchTitle), findsOneWidget);
    expect(find.text(AppCopy.safetyBanner), findsOneWidget);

    await tester.tap(find.text(AppCopy.startChat));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.proposeMeetup));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.meetupPlace), findsOneWidget);
    expect(find.text(AppCopy.meetupTime), findsOneWidget);
    await tester.tap(find.text(AppCopy.send));
    await tester.pumpAndSettle();
    expect(find.textContaining('만남 제안'), findsWidgets);
    expect(
      container.read(analyticsProvider).events,
      contains(MeetKpi.proposalSent),
    );
  });

  testWidgets('H01 species filter chips 전체|견|묘', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    expect(find.text(AppCopy.filterAll), findsOneWidget);
    expect(find.text(AppCopy.speciesDog), findsOneWidget);
    expect(find.text(AppCopy.speciesCat), findsOneWidget);
    expect(find.byKey(const ValueKey('home-card-kong')), findsOneWidget);

    await tester.tap(find.text(AppCopy.speciesCat));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-card-bam')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-card-kong')), findsNothing);
    expect(find.textContaining('밤이'), findsWidgets);

    await tester.tap(find.text(AppCopy.speciesDog));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-card-kong')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-card-bam')), findsNothing);
  });

  testWidgets('inbound meetup CTAs track accept and counter KPIs', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.startChat));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.meetupAccept), findsOneWidget);
    expect(find.text(AppCopy.meetupCounter), findsOneWidget);
    expect(find.text(AppCopy.meetupIgnore), findsOneWidget);

    await tester.tap(find.text(AppCopy.meetupAccept));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.meetupAccepted), findsOneWidget);
    expect(
      container.read(analyticsProvider).events,
      contains(MeetKpi.proposalAccepted),
    );
  });

  testWidgets('inbound meetup counter opens C03 and tracks KPI', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.startChat));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.meetupCounter));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.meetupPlace), findsOneWidget);
    expect(
      container.read(analyticsProvider).events,
      contains(MeetKpi.proposalCounter),
    );
  });

  test('P03 tag keys match locked labels', () {
    const expected = <String, String>{
      'walk_lover': '산책 좋아해요',
      'cafe_lover': '카페 가는 걸 즐겨요',
      'night_active': '밤에 활발해요',
      'nap_lover': '낮잠 매니아',
      'careful_with_strangers': '낯선 개 조심해요',
      'social_butterfly': '친구 많아요',
      'quiet_meetups': '조용한 만남 좋아요',
      'park_lover': '공원 러버',
      'indoor': '실내파',
      'weekend_morning': '주말 아침형',
      'after_work_walk': '퇴근 후 산책',
      'travel_mate': '여행 메이트',
    };
    expect(PetTags.all, hasLength(12));
    expect({for (final tag in PetTags.all) tag.key: tag.label}, expected);
  });

  test('H01 layout tokens match checklist', () {
    expect(AppColors.bg, const Color(0xFFFFFFFF));
    expect(AppConstants.searchRadiusKm, 5);
    expect(AppIcons.spark, Icons.auto_awesome);
    expect(AppSizes.passFab, 56);
    expect(AppSizes.likeFab, 64);
    expect(AppSizes.fabGap, 24);
    expect(AppSizes.cardInset, 32);
    expect(AppSizes.cardPhotoShare, 0.62);
    expect(AppSizes.cardPhotoAspect, 4 / 5);
    expect(AppSizes.sparkSegmentHeight, 40);
    expect(AppSizes.sparkRowHeight, 72);
    expect(AppSizes.sparkThumb, 48);
    expect(AppRadius.card, 20);
    expect(GoalCopy.homeTitle(UserGoal.friend), '오늘의 반짝 친구');
    expect(GoalCopy.homeTitle(UserGoal.walk), '같이 산책할 짝');
    expect(SpeciesCopy.noun(PetSpecies.dog), AppCopy.petNounDog);
    expect(SpeciesCopy.noun(PetSpecies.cat), AppCopy.petNounCat);
    expect(SpeciesCopy.noun(null), AppCopy.petNounFallback);
    expect(MeetKpi.proposalSent, 'meet_proposal_sent');
    expect(MeetKpi.proposalAccepted, 'meet_proposal_accepted');
    expect(MeetKpi.proposalCounter, 'meet_proposal_counter');
    expect(IdentityContract.verifiedAtField, 'verifiedAt');
    expect(IdentityContract.likesCollection, 'likes');
    expect(IdentityContract.matchesCollection, 'matches');
    expect(IdentityContract.petsCollection, 'pets');
    expect(IdentityContract.threadsCollection, 'threads');
    expect(IdentityContract.meetProposalsCollection, 'meetProposals');
    expect(IdentityContract.blocksCollection, 'blocks');
    expect(IdentityContract.reportsCollection, 'reports');
    expect(IdentityContract.markUserVerifiedCallable, 'markUserVerified');
    expect(IdentityContract.functionsRegion, 'asia-northeast3');
    expect(IdentityContract.failedPrecondition, 'failed-precondition');
    expect(AppCopy.likeNeedsVerify, '인증 후 반짝할 수 있어요');
    expect(AppCopy.verifyGateTitle, '안전하게 반짝해요');
    expect(AppCopy.verifyDone, '인증됐어요');
    expect(AppCopy.verifyGoSpark, '반짝하러 가기');
  });

  test('markUserVerified mock returns uid and ISO when Auth is absent', () async {
    expect(IdentityRemote.isLiveAuthReady, isFalse);
    final result = await IdentityVerification.requestMarkVerified(uid: 'u1');
    expect(result, isNotNull);
    expect(result!.uid, 'u1');
    expect(DateTime.tryParse(result.verifiedAtIso), isNotNull);
  });

  test('client dart never writes users.verifiedAt', () {
    final writeVerifiedAt = RegExp(
      r'''(verifiedAtField|'verifiedAt'|"verifiedAt")\s*:\s*''',
    );
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in dartFiles) {
      final src = file.readAsStringSync();
      expect(writeVerifiedAt.hasMatch(src), isFalse, reason: file.path);
    }
  });

  testWidgets('unverified like opens gate sheet; pass still works', (tester) async {
    final container = _loggedIn(verified: false);
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    expect(container.read(isVerifiedProvider), isFalse);
    expect(find.text(AppCopy.likeNeedsVerify), findsOneWidget);
    expect(find.byKey(const ValueKey('home-card-kong')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pass-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-card-bori')), findsOneWidget);
    expect(find.text(AppCopy.verifyGateTitle), findsNothing);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.verifyGateTitle), findsOneWidget);
    expect(find.text(AppCopy.verifyGateBody), findsOneWidget);

    await tester.tap(find.text(AppCopy.later));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.verifyGateTitle), findsNothing);
    expect(container.read(isVerifiedProvider), isFalse);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.verifyCta));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.verifyTitle), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('a02-confirm')));
    await tester.pumpAndSettle();
    expect(container.read(isVerifiedProvider), isTrue);
    expect(find.text(AppCopy.verifyDone), findsWidgets);
    expect(find.text(AppCopy.verifySuccessBody), findsOneWidget);
    expect(find.byKey(const ValueKey('trust-badge')), findsOneWidget);

    await tester.tap(find.text(AppCopy.verifyGoSpark));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.likeNeedsVerify), findsNothing);
    expect(find.text(GoalCopy.homeTitle(UserGoal.friend)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-card-bori')), findsNothing);
    expect(find.text(AppCopy.matchTitle), findsNothing);
  });

  testWidgets('verifiedAt stream restores H01 like CTA in place', (tester) async {
    final container = _loggedIn(verified: false);
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    expect(find.text(AppCopy.likeNeedsVerify), findsOneWidget);
    final like = find.byKey(const ValueKey('like-button'));
    final likeEl = tester.element(like);

    container.read(userDocProvider.notifier).ingestListenSnapshot(
          verifiedAt: DateTime.utc(2026, 9, 8, 12),
        );
    await tester.pump();

    expect(tester.element(like), same(likeEl));
    expect(find.text(AppCopy.likeNeedsVerify), findsNothing);
    expect(find.text(GoalCopy.homeTitle(UserGoal.friend)), findsOneWidget);
  });

  testWidgets('verifiedAt stream restores D01 walk CTA in place', (tester) async {
    final container = _loggedIn(goal: UserGoal.walk, verified: false);
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await tester.tap(find.byKey(const ValueKey('home-card-kong')));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.likeNeedsVerify), findsWidgets);
    expect(find.text(GoalCopy.detailCta(UserGoal.walk, '콩이')), findsNothing);
    final cta = find.byKey(const ValueKey('d01-cta'));
    final ctaEl = tester.element(cta);

    container.read(userDocProvider.notifier).ingestListenSnapshot(
          verifiedAt: DateTime.utc(2026, 9, 8, 12),
        );
    await tester.pump();

    expect(tester.element(cta), same(ctaEl));
    expect(find.text(GoalCopy.detailCta(UserGoal.walk, '콩이')), findsOneWidget);
    expect(find.text(AppCopy.likeNeedsVerify), findsNothing);
  });

  testWidgets('unverified D01 CTA sheet then A02 restores friend CTA', (tester) async {
    final container = _loggedIn(verified: false);
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    await tester.tap(find.byKey(const ValueKey('home-card-kong')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.likeNeedsVerify), findsWidgets);
    expect(find.text(GoalCopy.detailCta(UserGoal.friend, '콩이')), findsNothing);
    expect(find.byKey(const ValueKey('trust-badge')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('d01-cta')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.verifyGateTitle), findsOneWidget);

    await tester.tap(find.text(AppCopy.verifyCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('a02-confirm')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.verifyDone), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text(GoalCopy.detailCta(UserGoal.friend, '콩이')), findsOneWidget);
    expect(find.text(AppCopy.likeNeedsVerify), findsNothing);

    await tester.tap(find.byKey(const ValueKey('d01-cta')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.matchTitle), findsOneWidget);
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
