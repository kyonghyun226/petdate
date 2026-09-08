import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/state/analytics_provider.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/safety_banner.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('C02 UI order: banner, insert-only chips, meetup, bubble',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = testContainer(
      auth: FakeAuthRepository(
        signedInUser: const AuthUser(uid: 'mock_uid', providerId: 'google.com'),
      ),
    );
    addTearDown(container.dispose);
    seedCompletedSession(container, goal: UserGoal.friend);
    container.read(userDocProvider.notifier).ingestListenSnapshot(
          verifiedAt: DateTime.utc(2026, 9, 8),
        );

    await tester.pumpWidget(testApp(container: container));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.startChat));
    await tester.pumpAndSettle();

    // 1) 안전배너
    expect(find.byType(SafetyBanner), findsOneWidget);
    expect(find.text(AppCopy.safetyBanner), findsOneWidget);
    expect(AppColors.safetyBg, const Color(0xFFE8F7F3));
    expect(AppColors.safetyText, const Color(0xFF2F6F62));

    // 2) 칩3 insert-only (발신 0일 때만)
    final chips = GoalCopy.firstMessageChips(
      UserGoal.friend,
      AppCopy.fallbackPetName,
    );
    expect(chips, hasLength(3));
    expect(find.byKey(const ValueKey('first-message-chips')), findsOneWidget);
    expect(find.byKey(const ValueKey('first-message-chip-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('first-message-chip-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('first-message-chip-2')), findsOneWidget);
    expect(container.read(chatProvider).threads.single.outboundCount, 0);

    await tester.tap(find.byKey(const ValueKey('first-message-chip-0')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('c02-input')))
          .controller
          ?.text,
      chips.first,
    );
    expect(container.read(chatProvider).threads.single.outboundCount, 0);
    expect(
      container.read(chatProvider).threads.single.messages.where(
            (m) => m.isMine && m.kind == ChatMessageKind.text,
          ),
      isEmpty,
    );
    expect(
      container.read(analyticsProvider).events,
      contains(MeetKpi.firstMessageTemplateUsed),
    );
    expect(find.byKey(const ValueKey('first-message-chips')), findsOneWidget);

    // 3) 만남제안 진입
    await tester.tap(find.byKey(const ValueKey('meetup-propose-chip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('c03-meetup-sheet')), findsOneWidget);
    expect(find.text(AppCopy.meetupFriendTitle), findsOneWidget);

    // 4) 버블 채팅 — 보내면 카드 버블, 발신>0이면 첫인사 칩 사라짐
    await tester.tap(find.byKey(const ValueKey('meetup-send')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.proposeMeetup), findsWidgets);
    expect(find.text(AppCopy.meetupPlace), findsWidgets);
    expect(find.text(AppCopy.meetupTime), findsWidgets);
    expect(
      container.read(chatProvider).threads.single.messages.where(
            (m) => m.kind == ChatMessageKind.meetup,
          ),
      isNotEmpty,
    );
    expect(
      container.read(chatProvider).threads.single.outboundCount,
      greaterThan(0),
    );
    expect(find.byKey(const ValueKey('first-message-chips')), findsNothing);
    expect(
      container.read(analyticsProvider).events,
      contains(MeetKpi.proposalSent),
    );
  });
}
