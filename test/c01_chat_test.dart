import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/data/mock_social_repository.dart';
import 'package:petdate/firebase/firestore_ids.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/screens/c02_chat_room/c02_chat_room_screen.dart';
import 'package:petdate/screens/main_shell/c01_chat_screen.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/state/spark_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_app.dart';

const _uid = 'mock_uid';

ProviderContainer _loggedIn() {
  final container = testContainer(
    auth: FakeAuthRepository(
      signedInUser: const AuthUser(uid: _uid, providerId: 'google.com'),
    ),
  );
  seedCompletedSession(container, goal: UserGoal.friend);
  container.read(userDocProvider.notifier).ingestListenSnapshot(
        verifiedAt: DateTime.utc(2026, 9, 8),
      );
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

Future<void> _openChat(WidgetTester tester) async {
  await tester.tap(find.text(AppCopy.navChat));
  await tester.pumpAndSettle();
}

ChatThread _thread({
  required DiscoveryProfile profile,
  bool unread = false,
  bool unavailable = false,
  String preview = '주말 한강 산책 어때요?',
  DateTime? updatedAt,
  String? myUid,
}) {
  final uid = myUid ?? _uid;
  return ChatThread(
    id: FirestoreIds.matchId(uid, profile.id),
    profile: profile,
    unread: unread,
    unavailable: unavailable,
    updatedAt: updatedAt ?? DateTime.utc(2026, 9, 8, 11, 52),
    participantIds: {uid, profile.id},
    messages: [
      ChatMessage(
        id: 'sys_${profile.id}',
        text: AppCopy.chatSystemMatch,
        isMine: false,
        kind: ChatMessageKind.system,
      ),
      ChatMessage(
        id: 'msg_${profile.id}',
        text: preview,
        isMine: false,
      ),
    ],
  );
}

void main() {
  test('C01 tokens and copy match spec', () {
    expect(AppSizes.chatRowHeight, 72);
    expect(AppSizes.chatThumb, 48);
    expect(AppSizes.chatUnreadDot, 8);
    expect(AppColors.primary, const Color(0xFFFF6B4A));
    expect(AppColors.bg, const Color(0xFFFFFFFF));
    expect(AppColors.border, const Color(0xFFEFEFEF));
    expect(AppCopy.chatEmpty, '아직 반짝한 친구가 없어요');
    expect(AppCopy.goHome, '홈으로');
    expect(AppCopy.navChat, '채팅');
    final now = DateTime.utc(2026, 9, 8, 12);
    expect(
      formatChatTime(now.subtract(const Duration(minutes: 8)), now: now),
      '8분 전',
    );
  });

  test('visible hides blocked, withdrawn, and non-participant threads', () {
    final container = _loggedIn();
    addTearDown(container.dispose);
    final dal = MockCatalog.byId('dal')!;
    container.read(chatProvider.notifier).replaceForTest(
      threads: [
        _thread(profile: dal, unread: true),
        _thread(profile: MockCatalog.blocked, unread: true),
        _thread(
          profile: MockCatalog.byId('gureum')!,
          unavailable: true,
          unread: true,
        ),
        _thread(
          profile: MockCatalog.byId('bori')!,
          myUid: 'other_user_0000001',
        ),
      ],
    );

    final blocked = container.read(sparkProvider).blockedIds;
    final visible = container.read(chatProvider).visible(blocked, myUid: _uid);
    expect(visible.map((t) => t.profile.id), ['dal']);
    expect(visible.single.unread, isTrue);
    expect(visible.single.preview, '주말 한강 산책 어때요?');
  });

  testWidgets('empty state is copy + primary outline 홈으로', (tester) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    await _pumpMain(tester, container);
    await _openChat(tester);

    expect(find.text(AppCopy.chatEmpty), findsOneWidget);
    expect(find.byType(C01ChatScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(C01ChatScreen),
        matching: find.byType(PrimaryOutlineButton),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(C01ChatScreen),
        matching: find.byType(PrimaryButton),
      ),
      findsNothing,
    );

    final outlined = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byType(C01ChatScreen),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(outlined.style!.foregroundColor!.resolve(const {}), AppColors.primary);
    expect(outlined.style!.side!.resolve(const {})!.color, AppColors.primary);

    await tester.tap(find.text(AppCopy.goHome));
    await tester.pumpAndSettle();
    expect(find.text(GoalCopy.homeTitle(UserGoal.friend)), findsOneWidget);
  });

  testWidgets('unread row shows primary dot, time, and opens C02', (
    tester,
  ) async {
    final container = _loggedIn();
    addTearDown(container.dispose);
    final dal = MockCatalog.byId('dal')!;
    container.read(chatProvider.notifier).replaceForTest(
      threads: [
        _thread(
          profile: dal,
          unread: true,
          updatedAt: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        _thread(profile: MockCatalog.blocked, unread: true),
      ],
    );
    await _pumpMain(tester, container);
    await _openChat(tester);

    expect(find.text(AppCopy.chatEmpty), findsNothing);
    expect(find.byKey(const ValueKey('chat-row-dal')), findsOneWidget);
    expect(find.text('달이'), findsOneWidget);
    expect(find.text('주말 한강 산책 어때요?'), findsOneWidget);
    expect(find.text('8분 전'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-row-nuri')), findsNothing);

    expect(
      tester.getSize(find.byKey(const ValueKey('chat-row-dal'))).height,
      72,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-thumb-dal'))),
      const Size(48, 48),
    );
    final row = tester.widget<Container>(
      find.byKey(const ValueKey('chat-row-dal')),
    );
    expect(
      (row.decoration as BoxDecoration).border?.bottom.color,
      const Color(0xFFEFEFEF),
    );
    final preview = tester.widget<Text>(find.text('주말 한강 산책 어때요?'));
    expect(preview.maxLines, 1);
    expect(preview.overflow, TextOverflow.ellipsis);
    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(C01ChatScreen),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, AppColors.bg);

    final dot = tester.widget<Container>(
      find.byKey(const ValueKey('chat-unread-dal')),
    );
    expect((dot.decoration as BoxDecoration).color, const Color(0xFFFF6B4A));
    expect((dot.decoration as BoxDecoration).shape, BoxShape.circle);

    await tester.tap(find.byKey(const ValueKey('chat-row-dal')));
    await tester.pumpAndSettle();
    expect(find.byType(C02ChatRoomScreen), findsOneWidget);
    expect(find.text(AppCopy.chatSystemMatch), findsOneWidget);
    expect(
      container.read(chatProvider).byProfile('dal')?.unread,
      isFalse,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(C01ChatScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-unread-dal')), findsNothing);
  });

  test('mock watchThreads is participant-only', () async {
    final repo = MockSocialRepository(catalog: MockCatalog.profiles);
    addTearDown(repo.dispose);
    final dal = MockCatalog.byId('dal')!;
    repo.ensureThread(
      _uid,
      dal,
      messages: [
        const ChatMessage(
          id: 'sys',
          text: AppCopy.chatSystemMatch,
          isMine: false,
          kind: ChatMessageKind.system,
        ),
      ],
      unread: true,
    );

    final mine = await repo.watchThreads(myUid: _uid).first;
    expect(mine, hasLength(1));
    expect(mine.single.profile.id, 'dal');
    expect(mine.single.unread, isTrue);

    final other = await repo.watchThreads(myUid: 'someoneelse000001').first;
    expect(other, isEmpty);

    repo.withdrawUser('dal');
    final afterWithdraw = await repo.watchThreads(myUid: _uid).first;
    expect(afterWithdraw, isEmpty);
  });
}
