import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/screens/c02_chat_room/c02_chat_room_screen.dart';
import 'package:petdate/screens/c03_meetup/c03_meetup_sheet.dart';
import 'package:petdate/state/analytics_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_app.dart';

ProviderContainer _loggedIn() {
  final container = testContainer(
    auth: FakeAuthRepository(
      signedInUser: const AuthUser(uid: 'mock_uid', providerId: 'google.com'),
    ),
  );
  seedCompletedSession(container);
  container.read(userDocProvider.notifier).ingestListenSnapshot(
        verifiedAt: DateTime.utc(2026, 9, 8),
      );
  return container;
}

Future<void> _pumpMain(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(testApp(container: container));
  await tester.pumpAndSettle();
}

Future<void> _openMatchedChat(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('like-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(AppCopy.startChat));
  await tester.pumpAndSettle();
}

void main() {
  test('C02/C03 tokens and copy match spec', () {
    expect(AppColors.safetyBg, const Color(0xFFE8F7F3));
    expect(AppColors.safetyText, const Color(0xFF2F6F62));
    expect(AppColors.primarySoft, const Color(0xFFFFE5DE));
    expect(AppColors.primary, const Color(0xFFFF6B4A));
    expect(AppRadius.chip, 999);
    expect(AppRadius.sheetTop, 24);
    expect(AppSizes.templateChipHeight, 36);
    expect(AppCopy.safetyBanner, '만남은 공공장소에서, 반려와 함께 안전하게');
    expect(AppCopy.meetupTitle, '어디서 만날까요?');
    expect(AppCopy.meetupTimeChips, [
      '오늘 저녁',
      '이번 주말',
      '날짜·시간 선택',
    ]);
    expect(MeetupPlaceCopy.label(MeetupPlace.park), '공원');
    expect(MeetupPlaceCopy.label(MeetupPlace.petCafe), '펫카페');
    expect(MeetupPlaceCopy.label(MeetupPlace.other), '기타');
    expect(MeetKpi.proposalSent, 'meet_proposal_sent');
    expect(MeetKpi.proposalAccepted, 'meet_proposal_accepted');
    expect(MeetKpi.proposalCounter, 'meet_proposal_counter');
    expect(formatPetDistance(0.8), '800m');
  });

  testWidgets('C03 send and inbound CTAs track meet KPIs', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openMatchedChat(tester);

    expect(find.text(AppCopy.meetupPlace), findsWidgets);
    expect(find.text(AppCopy.meetupTime), findsWidgets);
    expect(find.text(AppCopy.meetupAccept), findsOneWidget);
    expect(find.text(AppCopy.meetupCounter), findsOneWidget);
    expect(find.text(AppCopy.meetupIgnore), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meetup-propose-chip')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.meetupTitle), findsOneWidget);
    expect(find.text(MeetupPlaceCopy.label(MeetupPlace.park)), findsWidgets);
    expect(find.text(MeetupPlaceCopy.label(MeetupPlace.petCafe)), findsOneWidget);
    expect(find.text(MeetupPlaceCopy.label(MeetupPlace.other)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meetup-send')));
    await tester.pumpAndSettle();
    expect(container.read(analyticsProvider).events, contains(MeetKpi.proposalSent));
    expect(find.text(AppCopy.meetupSent), findsOneWidget);
    expect(find.text(AppCopy.proposeMeetup), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('meetup-accept')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.meetupAccepted), findsOneWidget);
    expect(
      container.read(analyticsProvider).events,
      containsAll([
        MeetKpi.proposalSent,
        MeetKpi.proposalAccepted,
      ]),
    );
  });

  testWidgets('inbound counter CTA opens C03 and tracks KPI', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openMatchedChat(tester);

    await tester.tap(find.byKey(const ValueKey('meetup-counter')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.meetupTitle), findsOneWidget);
    expect(
      container.read(analyticsProvider).events,
      contains(MeetKpi.proposalCounter),
    );
    expect(find.text(AppCopy.meetupIgnored), findsNothing);

    await tester.tap(find.text(AppCopy.send));
    await tester.pumpAndSettle();
    expect(
      container.read(analyticsProvider).events,
      containsAll([MeetKpi.proposalCounter, MeetKpi.proposalSent]),
    );
  });

  testWidgets('inbound ignore updates receipt without a KPI', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openMatchedChat(tester);

    await tester.tap(find.byKey(const ValueKey('meetup-ignore')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.meetupIgnored), findsOneWidget);
    expect(container.read(analyticsProvider).events, isEmpty);
  });

  testWidgets('header overflow offers profile report and block', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openMatchedChat(tester);

    await tester.tap(find.byTooltip(AppCopy.reportMenu));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.viewProfile), findsOneWidget);
    expect(find.text(AppCopy.reportMenuItem), findsOneWidget);
    expect(find.text(AppCopy.blockMenuItem), findsOneWidget);
  });

  testWidgets('unknown thread is members-only', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: C02ChatRoomScreen(threadId: 'not_a_member'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.chatMembersOnly), findsOneWidget);
  });

  testWidgets('C03 sheet radius and optional memo stay on spec', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: C03MeetupSheet(threadId: 'local')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.meetupTitle), findsOneWidget);
    expect(find.text(AppCopy.meetupMemo), findsOneWidget);

    final memo = tester.widget<TextField>(
      find.byKey(const ValueKey('meetup-memo')),
    );
    expect(memo.maxLength, 140);
  });
}
