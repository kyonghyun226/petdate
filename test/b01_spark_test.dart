import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/models/spark.dart';
import 'package:petdate/screens/main_shell/b01_spark_screen.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/state/spark_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/chips.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_app.dart';

ProviderContainer _loggedIn({bool verified = true}) {
  final container = testContainer(
    auth: FakeAuthRepository(
      signedInUser: const AuthUser(uid: 'mock_uid', providerId: 'google.com'),
    ),
  );
  seedCompletedSession(container);
  if (verified) {
    container
        .read(userDocProvider.notifier)
        .ingestListenSnapshot(verifiedAt: DateTime.utc(2026, 9, 8));
  }
  return container;
}

Future<void> _pumpMain(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(testApp(container: container));
  await tester.pumpAndSettle();
}

Future<void> _openSpark(WidgetTester tester) async {
  await tester.tap(find.text(AppCopy.navSpark));
  await tester.pumpAndSettle();
}

void main() {
  test('B01 tokens and copy match UIUX v1', () {
    expect(AppSizes.sparkSegmentHeight, 40);
    expect(AppSizes.sparkRowHeight, 72);
    expect(AppSizes.sparkThumb, 48);
    expect(AppColors.primarySoft, const Color(0xFFFFE5DE));
    expect(AppColors.primary, const Color(0xFFFF6B4A));
    expect(AppColors.border, const Color(0xFFEFEFEF));
    expect(AppIcons.spark, Icons.auto_awesome);
    expect(AppCopy.sparkReceived, '받은');
    expect(AppCopy.sparkSent, '보낸');
    expect(AppCopy.sparkMatched, '매칭됨');
    expect(AppCopy.sparkReply, '반짝 화답');
    expect(AppCopy.sparkReplyCta('콩이'), '우리 콩이와 친구될래?');
    expect(AppCopy.detailCta('초코'), '우리 초코와 친구하자!');
    expect(AppCopy.sparkEmpty, '아직 받은 반짝이 없어요');
    expect(AppCopy.sparkSentEmpty, '아직 보낸 반짝이 없어요');
    expect(AppCopy.sparkMatchedEmpty, '아직 반짝한 친구가 없어요');
  });

  test('spark caption is distance · relative time', () {
    final now = DateTime.utc(2026, 9, 8, 12);
    expect(formatSparkDistance(0.8), '800m');
    expect(
      formatSparkRelativeTime(
        now.subtract(const Duration(minutes: 8)),
        now: now,
      ),
      '8분 전',
    );
    expect(
      formatSparkRelativeTime(now.subtract(const Duration(hours: 2)), now: now),
      '2시간 전',
    );
    expect(
      formatSparkRelativeTime(now.subtract(const Duration(days: 1)), now: now),
      '어제',
    );
    expect(
      SparkItem(
        id: 'x',
        profile: MockCatalog.profiles.first,
        bucket: SparkBucket.received,
        createdAt: now.subtract(const Duration(minutes: 8)),
      ).metaCaption(now: now),
      '800m · 8분 전',
    );
  });

  test('spark provider seeds segments, hides blocks, counts unseen', () {
    final container = _loggedIn();
    addTearDown(container.dispose);
    final spark = container.read(sparkProvider);

    expect(spark.of(SparkBucket.received).map((e) => e.profile.id), [
      'kong',
      'bam',
    ]);
    expect(spark.of(SparkBucket.sent).map((e) => e.profile.id), ['bori']);
    expect(spark.of(SparkBucket.matched).map((e) => e.profile.id), ['dal']);
    expect(
      spark.of(SparkBucket.received).any((e) => e.profile.id == 'nuri'),
      isFalse,
    );
    expect(spark.unseenReceivedCount, 2);
  });

  testWidgets('badge is unseen received count and clears on 받은 tab', (
    tester,
  ) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);

    expect(find.byKey(const ValueKey('spark-badge')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spark-badge')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    await _openSpark(tester);
    expect(find.byKey(const ValueKey('spark-badge')), findsNothing);
    expect(container.read(sparkProvider).unseenReceivedCount, 0);
  });

  testWidgets('segments, rows, and blocked user stay off the lists', (
    tester,
  ) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openSpark(tester);

    expect(find.text(AppCopy.sparkReceived), findsOneWidget);
    expect(find.text(AppCopy.sparkSent), findsOneWidget);
    expect(find.text(AppCopy.sparkMatched), findsOneWidget);

    final selected = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('spark-segment-received')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((selected.decoration as BoxDecoration).color, AppColors.primarySoft);

    expect(find.byKey(const ValueKey('spark-row-kong')), findsOneWidget);
    expect(find.byKey(const ValueKey('spark-row-bam')), findsOneWidget);
    expect(find.byKey(const ValueKey('spark-row-nuri')), findsNothing);
    expect(find.text('누리'), findsNothing);
    expect(find.text(AppCopy.sparkReply), findsNWidgets(2));
    expect(find.textContaining('800m'), findsWidgets);
    expect(find.textContaining('분 전'), findsWidgets);

    final reply = find.byKey(const ValueKey('spark-reply-kong'));
    expect(
      find.descendant(of: reply, matching: find.byIcon(AppIcons.spark)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: reply, matching: find.byIcon(Icons.favorite)),
      findsNothing,
    );
    expect(
      find.descendant(of: reply, matching: find.byIcon(Icons.favorite_rounded)),
      findsNothing,
    );
    expect(
      find.descendant(of: reply, matching: find.byIcon(Icons.pets)),
      findsNothing,
    );
    expect(
      find.descendant(of: reply, matching: find.byIcon(Icons.pets_rounded)),
      findsNothing,
    );
    expect(find.byType(SparkReplyChip), findsNWidgets(2));

    await tester.tap(find.text(AppCopy.sparkSent));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spark-row-bori')), findsOneWidget);
    expect(find.byType(SparkReplyChip), findsNothing);

    await tester.tap(find.text(AppCopy.sparkMatched));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spark-row-dal')), findsOneWidget);
    expect(find.byType(SparkReplyChip), findsNothing);
  });

  testWidgets('empty states and optional 홈으로', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    container
        .read(sparkProvider.notifier)
        .replaceForTest(items: const [], blockedIds: const {});
    await _pumpMain(tester, container);
    await _openSpark(tester);

    expect(find.text(AppCopy.sparkEmpty), findsOneWidget);
    final receivedHome = find.descendant(
      of: find.byType(B01SparkScreen),
      matching: find.text(AppCopy.goHome),
    );
    expect(receivedHome, findsOneWidget);

    await tester.tap(find.text(AppCopy.sparkSent));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.sparkSentEmpty), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(B01SparkScreen),
        matching: find.text(AppCopy.goHome),
      ),
      findsNothing,
    );

    await tester.tap(find.text(AppCopy.sparkMatched));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.sparkMatchedEmpty), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(B01SparkScreen),
        matching: find.text(AppCopy.goHome),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(B01SparkScreen),
        matching: find.text(AppCopy.goHome),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.homeTitle), findsOneWidget);
  });

  testWidgets('received row opens D01 with their-pet reply CTA', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openSpark(tester);

    await tester.tap(find.byKey(const ValueKey('spark-row-kong')));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.sparkReplyCta('콩이')), findsOneWidget);
    expect(
      find.text(AppCopy.detailCta(AppCopy.fallbackPetName)),
      findsNothing,
    );
  });

  testWidgets('sent row opens D01 without match CTA', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openSpark(tester);

    await tester.tap(find.text(AppCopy.sparkSent));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('spark-row-bori')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('d01-cta')), findsNothing);
    expect(find.text(AppCopy.sparkReplyCta('보리')), findsNothing);
    expect(
      find.text(AppCopy.detailCta(AppCopy.fallbackPetName)),
      findsNothing,
    );
  });

  testWidgets('unverified 화답 opens A02 gate sheet', (tester) async {
    final container = _loggedIn(verified: false);
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openSpark(tester);

    await tester.tap(find.byKey(const ValueKey('spark-reply-kong')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.verifyGateTitle), findsOneWidget);
    expect(find.text(AppCopy.verifyGateCta), findsOneWidget);

    await tester.tap(find.text(AppCopy.later));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.verifyGateTitle), findsNothing);
    expect(
      container.read(sparkProvider).byProfile('kong')?.bucket,
      SparkBucket.received,
    );
  });

  testWidgets('verified 화답 matches, opens M01, then 매칭됨', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openSpark(tester);

    await tester.tap(find.byKey(const ValueKey('spark-reply-kong')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.matchTitle), findsOneWidget);

    await tester.tap(find.text(AppCopy.later));
    await tester.pumpAndSettle();

    expect(
      container.read(sparkProvider).byProfile('kong')?.bucket,
      SparkBucket.matched,
    );
    expect(find.byKey(const ValueKey('spark-row-kong')), findsOneWidget);
    expect(find.byKey(const ValueKey('spark-row-dal')), findsOneWidget);
    expect(find.byType(SparkReplyChip), findsNothing);

    final matched = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('spark-segment-matched')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((matched.decoration as BoxDecoration).color, AppColors.primarySoft);
  });

  testWidgets('매칭됨 row opens D01; start chat only when not started', (
    tester,
  ) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openSpark(tester);
    await tester.tap(find.text(AppCopy.sparkMatched));
    await tester.pumpAndSettle();

    // No prior chat activity in test mode → profile + start CTA
    await tester.tap(find.byKey(const ValueKey('spark-row-dal')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('d01-cta')), findsNothing);
    expect(find.text(AppCopy.chatSystemMatch), findsNothing);
    expect(find.text(AppCopy.startConversation), findsOneWidget);
    expect(find.byKey(const ValueKey('d01-start-chat')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('d01-start-chat')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.chatSystemMatch), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    // After opening C02 once, CTA is gone
    expect(find.byKey(const ValueKey('d01-start-chat')), findsNothing);
    expect(find.text(AppCopy.startConversation), findsNothing);
  });

  testWidgets('매칭됨 with text history hides start chat CTA', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    final dal = MockCatalog.byId('dal')!;
    container.read(chatProvider.notifier).replaceForTest(
      threads: [
        ChatThread(
          id: 'match_dal',
          profile: dal,
          messages: const [
            ChatMessage(
              id: 't1',
              text: '주말 아침 산책 가능해요',
              isMine: false,
            ),
          ],
        ),
      ],
    );
    await _pumpMain(tester, container);
    await _openSpark(tester);
    await tester.tap(find.text(AppCopy.sparkMatched));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('spark-row-dal')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('d01-start-chat')), findsNothing);
    expect(find.byKey(const ValueKey('d01-cta')), findsNothing);
  });

  testWidgets('R01 block removes the row from every B01 segment', (
    tester,
  ) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openSpark(tester);

    await tester.tap(find.byKey(const ValueKey('spark-row-kong')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppCopy.reportMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.blockLabel));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('spark-row-kong')), findsNothing);
    expect(
      container
          .read(sparkProvider)
          .of(SparkBucket.received)
          .any((e) => e.profile.id == 'kong'),
      isFalse,
    );
  });
}
