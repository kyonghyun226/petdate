import 'package:flutter/material.dart';
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
  testWidgets('C02 UI order: banner, meetup chip, bubble', (tester) async {
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
    seedCompletedSession(container);
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

    // 2) 예시 첫인사 칩은 없음
    expect(find.byKey(const ValueKey('first-message-chips')), findsNothing);

    // 3) 만남제안 진입
    await tester.tap(find.byKey(const ValueKey('meetup-propose-chip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('c03-meetup-sheet')), findsOneWidget);
    expect(find.text(AppCopy.meetupTitle), findsOneWidget);

    // 4) 버블 채팅 — 보내면 카드 버블
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
    expect(
      container.read(analyticsProvider).events,
      contains(MeetKpi.proposalSent),
    );
  });
}
